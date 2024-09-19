package kafva.kage.ui.views

import androidx.compose.foundation.layout.Column
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Face
import androidx.compose.material.icons.filled.AccountBox
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.ui.Modifier
import androidx.compose.runtime.Composable
import kafva.kage.data.PwNode
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.lazy.LazyColumn

@Composable
public fun TreeView(node: PwNode) {
    LazyColumn(modifier = Modifier.fillMaxWidth(0.8f)) {
        node.children.forEach { child ->
            item {
                TreeChildView(child)
            }
        }
    }
}

@Composable
fun TreeChildView(node: PwNode, depth: Int = 0) {
    if (!node.children.isEmpty()) {
        ListItem(
            headlineContent = { Text(text = node.name) },
            leadingContent = {
                Icon(
                    Icons.Filled.AccountBox,
                    contentDescription = "Folder",
                )
            },
            modifier = Modifier.padding(start = (depth * 10).dp)
        )
        HorizontalDivider(modifier = Modifier.padding(start = (depth * 10).dp))

        node.children.forEach { child ->
            TreeChildView(child, depth + 1)
        }
    }
    else {
        ListItem(
            headlineContent = { Text(text = node.name) },
            leadingContent = {
                Icon(
                    Icons.Filled.Face,
                    contentDescription = "Password",
                )
            },
            modifier = Modifier.padding(start = (depth * 5).dp)
        )
        HorizontalDivider(modifier = Modifier.padding(start = (depth * 10).dp))
    }
}
