package kafva.kage.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kafva.kage.G
import kafva.kage.R
import kafva.kage.models.TreeViewModel
import kafva.kage.types.PwNode

@Composable
fun TreeView(
    navigateToPassword: (node: PwNode) -> Unit,
    viewModel: TreeViewModel = hiltViewModel()
) {
    val searchMatches by viewModel.gitRepository.searchMatches.collectAsState()
    val expandRecursively by viewModel.runtimeSettingsRepository
                                      .expandRecursively.collectAsStateWithLifecycle()

    LazyColumn(modifier = G.containerModifier) {
        searchMatches.forEach { child ->
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
    val icon: ImageVector
    val desc: String

    if (isPassword) {
        icon = Icons.Outlined.Lock
        desc = "Password"
    }
    else {
        icon = if (expanded) Icons.Filled.KeyboardArrowDown else
                             Icons.AutoMirrored.Filled.KeyboardArrowRight
        desc = "Folder"
    }

    ListItem(
        headlineContent = { Text(text = node.name) },
        leadingContent = {
            Icon(icon, contentDescription = desc, modifier = Modifier.size(24.dp))
        },
        modifier = Modifier.padding(start = (depth * 15).dp, bottom = 10.dp)
                           .clip(RoundedCornerShape(50))
                           .clickable {
            if (isPassword) {
                navigateToPassword(node)
            }
            else {
                isExpanded = !isExpanded
            }
        },
        colors = ListItemDefaults.colors(
          containerColor = MaterialTheme.colorScheme.surfaceVariant,
        )
    )
    if (!isPassword && expanded) {
        node.children.forEach { child ->
            TreeChildView(child, expandRecursively, navigateToPassword, depth + 1)
        }
    }
}
