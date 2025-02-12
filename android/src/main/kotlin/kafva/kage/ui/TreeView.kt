package kafva.kage.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import dagger.hilt.android.lifecycle.HiltViewModel
import kafva.kage.G
import kafva.kage.data.GitRepository
import kafva.kage.data.RuntimeSettingsRepository
import kafva.kage.types.PwNode
import javax.inject.Inject

@HiltViewModel
class TreeViewModel
    @Inject
    constructor(
        val gitRepository: GitRepository,
        val runtimeSettingsRepository: RuntimeSettingsRepository,
    ) : ViewModel()

@Composable
fun TreeView(
    navigateToPassword: (node: PwNode) -> Unit,
    viewModel: TreeViewModel = hiltViewModel(),
) {
    val searchMatches by viewModel.gitRepository.searchMatches.collectAsState()
    val expandRecursively by viewModel.runtimeSettingsRepository
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
    LazyColumn(modifier = G.containerModifier) {
        sortedMatches.forEach { child ->
            item {
                TreeChildView(child, expandRecursively, navigateToPassword)
            }
        }
    }

    LaunchedEffect(Unit) {
        viewModel.gitRepository.setup()
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

    ListItem(
        headlineContent = {
            Text(
                text = node.name,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        },
        leadingContent = {
            if (!isPassword) {
                val icon =
                    if (expanded) {
                        Icons.Filled.KeyboardArrowDown
                    } else {
                        Icons.AutoMirrored.Filled.KeyboardArrowRight
                    }
                Icon(
                    icon,
                    contentDescription = "Folder",
                    modifier = Modifier.size(G.MEDIUM_ICON_SIZE.dp),
                )
            }
        },
        modifier =
            Modifier
                .padding(start = (depth * 15).dp, bottom = 10.dp)
                .clip(RoundedCornerShape(G.CORNER_RADIUS))
                .clickable {
                    if (isPassword) {
                        navigateToPassword(node)
                    } else {
                        isExpanded = !isExpanded
                    }
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
}
