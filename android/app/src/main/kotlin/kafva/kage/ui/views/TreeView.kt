package kafva.kage.ui.views

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.Modifier
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import kafva.kage.data.PwNode
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Box
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clip
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Person


@Composable
public fun TreeView(node: PwNode, expandRecursively: Boolean = false) {
    LazyColumn(modifier = Modifier.fillMaxWidth(0.8f)) {
        node.children.forEach { child ->
            item {
                TreeChildView(child, expandRecursively)
            }
        }
    }
}

@Composable
fun TreeChildView(node: PwNode, expandRecursively: Boolean = false, depth: Int = 0) {
    var isExpanded by remember { mutableStateOf(true) }
    val expanded = isExpanded || expandRecursively

    if (!node.children.isEmpty()) {
        val iconFolder = if (expanded) Icons.Filled.KeyboardArrowDown else
                                       Icons.Filled.KeyboardArrowRight
        ListItem(
            headlineContent = { Text(text = node.name) },
            leadingContent = {
                Icon(
                    iconFolder,
                    contentDescription = "Folder",
                )
            },
            modifier = Modifier.clip(RoundedCornerShape(50))
                               .background(MaterialTheme.colorScheme.primary)
                               .padding(start = (depth * 10).dp)
                               .clickable { isExpanded = !isExpanded }
        )

        HorizontalDivider(modifier = Modifier.padding(start = (depth * 10).dp))

        if (expanded) {
            node.children.forEach { child ->
                TreeChildView(child, expandRecursively, depth + 1)
            }
        }
    }
    else {
        ListItem(
            headlineContent = { Text(text = node.name) },
            leadingContent = {
                Icon(
                    Icons.Filled.Person,
                    contentDescription = "Password",
                )
            },
            modifier = Modifier.padding(start = (depth * 5).dp)
        )
        HorizontalDivider(modifier = Modifier.padding(start = (depth * 10).dp))
    }
}
