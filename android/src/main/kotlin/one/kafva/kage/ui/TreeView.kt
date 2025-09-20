package one.kafva.kage.ui

import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import one.kafva.kage.BODY_FONT_SIZE
import one.kafva.kage.CONTAINER_MODIFIER
import one.kafva.kage.CORNER_RADIUS
import one.kafva.kage.ICON_SIZE
import one.kafva.kage.Log
import one.kafva.kage.R
import one.kafva.kage.data.GitDataSource
import one.kafva.kage.data.GitException
import one.kafva.kage.data.RuntimeSettingsDataSource
import one.kafva.kage.types.PwNode
import javax.inject.Inject

@HiltViewModel
class TreeViewModel
    @Inject
    constructor(
        val gitDataSource: GitDataSource,
        val runtimeSettingsDataSource: RuntimeSettingsDataSource,
    ) : ViewModel()

@Composable
fun TreeView(
    navigateToPassword: (node: PwNode) -> Unit,
    viewModel: TreeViewModel = hiltViewModel(),
) {
    val searchMatches by viewModel.gitDataSource.searchMatches.collectAsState()
    val expandRecursively by viewModel.runtimeSettingsDataSource
        .expandRecursively
        .collectAsStateWithLifecycle()

    val sortedMatches =
        searchMatches.sortedWith(
            compareBy(
                String.CASE_INSENSITIVE_ORDER,
            ) {
                it.name
            },
        )
    LazyColumn(modifier = CONTAINER_MODIFIER) {
        sortedMatches.forEach { child ->
            item {
                TreeChildView(child, expandRecursively, navigateToPassword)
            }
        }
    }

    LaunchedEffect(Unit) {
        viewModel.gitDataSource.setup()
    }
}

@Composable
private fun TreeChildView(
    node: PwNode,
    expandRecursively: Boolean,
    navigateToPassword: (node: PwNode) -> Unit,
    depth: Int = 0,
) {
    var isExpanded by remember { mutableStateOf(false) }
    val expanded = isExpanded || expandRecursively
    val isPassword = node.children.isEmpty()
    val openAlertDialog = remember { mutableStateOf(false) }
    val currentError: MutableState<String?> = remember { mutableStateOf(null) }

    ListItem(
        headlineContent = {
            Text(
                node.name,
                fontSize = BODY_FONT_SIZE.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier =
                    Modifier
                        .fillMaxWidth(1.0f)
                        .drawBehind {
                            val y = size.height + 2.0.toFloat()
                            drawLine(
                                Color.DarkGray,
                                Offset(0.0.toFloat(), y),
                                Offset(size.width, y),
                                0.5.toFloat(),
                            )
                        },
            )
        },
        trailingContent = {
            // Use transparent icon for password nodes to keep the same
            // text length.
            val tint =
                if (isPassword) {
                    Color.Transparent
                } else {
                    MaterialTheme.colorScheme.primary
                }
            val icon =
                if (expanded) {
                    Icons.Filled.KeyboardArrowDown
                } else {
                    Icons.AutoMirrored.Filled.KeyboardArrowRight
                }
            Icon(
                icon,
                contentDescription = "Folder",
                modifier = Modifier.size(ICON_SIZE.dp),
                tint = tint,
            )
        },
        modifier =
            Modifier
                .padding(start = (depth * 15).dp)
                .clip(RoundedCornerShape(CORNER_RADIUS))
                .pointerInput(Unit) {
                    detectTapGestures(
                        onLongPress = {
                            currentError.value = null
                            openAlertDialog.value = true
                        },
                        onTap = {
                            if (isPassword) {
                                navigateToPassword(node)
                            } else {
                                isExpanded = !isExpanded
                            }
                        },
                    )
                },
    )
    if (!isPassword && expanded) {
        val sortedChildren =
            node.children.sortedWith(
                compareBy(
                    String.CASE_INSENSITIVE_ORDER,
                ) {
                    it.name
                },
            )
        sortedChildren.forEach { child ->
            TreeChildView(
                child,
                expandRecursively,
                navigateToPassword,
                depth + 1,
            )
        }
    }

    AlertView(node, openAlertDialog, currentError)
}

@Composable
private fun AlertView(
    node: PwNode,
    openAlertDialog: MutableState<Boolean>,
    currentError: MutableState<String?>,
    viewModel: TreeViewModel = hiltViewModel(),
) {
    val coroutineScope = rememberCoroutineScope()

    val deleteNode: () -> Unit = {
        coroutineScope.launch {
            try {
                viewModel.gitDataSource.remove(node)
                // Reload tree after deleteion
                viewModel.gitDataSource.setup()
                openAlertDialog.value = false
            } catch (e: GitException) {
                currentError.value = e.message ?: "Unknown error"
                Log.e(currentError.value.toString())
            }
        }
    }

    if (openAlertDialog.value) {
        AlertDialog(
            title = {
                Text(node.name)
            },
            text = {
                if (currentError.value != null) {
                    Text(
                        currentError.value.toString(),
                        color = Color.Red,
                    )
                } else {
                    Text(stringResource(R.string.edit_node_text))
                }
            },
            onDismissRequest = {
                openAlertDialog.value = false
            },
            confirmButton = {
                TextButton(onClick = deleteNode) {
                    Text(stringResource(R.string.delete), color = Color.Red)
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        openAlertDialog.value = false
                    },
                ) {
                    Text(
                        stringResource(R.string.cancel),
                        color = MaterialTheme.colorScheme.onBackground,
                    )
                }
            },
            modifier = Modifier.fillMaxWidth(0.70f),
        )
    }
}
