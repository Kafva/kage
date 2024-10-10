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
import kafva.kage.types.Screen
import kafva.kage.data.PwNode
import kafva.kage.data.TreeViewModel
import androidx.compose.runtime.collectAsState
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavHostController
import android.content.Context
import androidx.compose.ui.platform.LocalContext

@Composable
fun TreeView(
    navController: NavHostController,
    viewModel: TreeViewModel = hiltViewModel()
) {
    val searchMatches by viewModel.gitRepository.searchMatches.collectAsStateWithLifecycle()
    val expandRecursively by viewModel.runtimeSettingsRepository
                                      .expandRecursively.collectAsStateWithLifecycle()

    LazyColumn(modifier = Modifier.fillMaxWidth(0.85f).padding(top = 10.dp)) {
        searchMatches.forEach { child ->
            item {
                TreeChildView(navController, child, expandRecursively)
            }
        }
    }
}

@Composable
private fun TreeChildView(
    navController: NavHostController,
    node: PwNode,
    expandRecursively: Boolean,
    depth: Int = 0
) {
    val context = LocalContext.current
    var isExpanded by remember { mutableStateOf(false) }
    val expanded = isExpanded || expandRecursively
    val isPassword = node.children.isEmpty()
    val icon: ImageVector
    val desc: String

    if (isPassword) {
        icon = Icons.Filled.Person
        desc = "Password"
    }
    else {
        icon = if (expanded) Icons.Filled.KeyboardArrowDown else
                             Icons.Filled.KeyboardArrowRight
        desc = "Folder"
    }

    ListItem(
        headlineContent = { Text(text = node.name) },
        leadingContent = {
            Icon(icon, contentDescription = desc)
        },
        modifier = Modifier.padding(start = (depth * 15).dp, bottom = 10.dp)
                           .clip(RoundedCornerShape(50))
                           .clickable {
            if (isPassword) {
                val filesDir = "${context.filesDir.path}/"
                val nodePath = node.pathString.removePrefix(filesDir).replace("/", "|")
                navController.navigate("${Screen.Password.route}/${nodePath}")
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
            TreeChildView(navController, child, expandRecursively, depth + 1)
        }
    }
}
