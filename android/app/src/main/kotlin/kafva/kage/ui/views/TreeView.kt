package kafva.kage.ui.views

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import kafva.kage.Log
import kafva.kage.data.PwNode
import kafva.kage.data.TreeViewModel
import androidx.compose.runtime.collectAsState

@Composable
fun TreeView(viewModel: TreeViewModel = hiltViewModel()) {
    var expandRecursively by remember { mutableStateOf(false) }
    val nodes by viewModel.nodes.collectAsState()

    Button(
        onClick = {
            expandRecursively = !expandRecursively
        },
    ) {
        Text("Toggle expansion")
    }

    nodes?.let { node ->
        TreeRootFolderView(node, expandRecursively)
    }
}

@Composable
private fun TreeRootFolderView(
    node: PwNode,
    expandRecursively: Boolean
) {
    LazyColumn(modifier = Modifier.fillMaxWidth(0.85f)) {
        node.children.forEach { child ->
            item {
                TreeChildView(child, expandRecursively)
            }
        }
    }
}

@Composable
private fun TreeChildView(
    node: PwNode,
    expandRecursively: Boolean,
    depth: Int = 0
) {
    var isExpanded by remember { mutableStateOf(false) }
    val expanded = isExpanded || expandRecursively
    val isPassword = node.children.isEmpty()
    val icon: ImageVector
    val desc: String
    val name: String

    if (isPassword) {
        icon = Icons.Filled.Person
        desc = "Password"
        name = node.name
    }
    else {
        name = node.name.removeSuffix(".age")
        icon = if (expanded) Icons.Filled.KeyboardArrowDown else
                             Icons.Filled.KeyboardArrowRight
        desc = "Folder"
    }

    ListItem(
        headlineContent = { Text(text = name) },
        leadingContent = {
            Icon(icon, contentDescription = desc)
        },
        modifier = Modifier.padding(start = (depth * 15).dp, bottom = 10.dp)
                           .clip(RoundedCornerShape(50))
                           .clickable {
            if (isPassword) {
                Log.i("TODO")
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
            TreeChildView(child, expandRecursively, depth + 1)
        }
    }
}
