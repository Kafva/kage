package kafva.kage.ui.views

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.Scaffold
import androidx.compose.material3.IconButton
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.FloatingActionButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.material.icons.Icons
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material3.BottomAppBarDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.SearchBar
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.Color
import androidx.hilt.navigation.compose.hiltViewModel
import kafva.kage.data.TreeViewModel


@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ToolbarView(
    treeViewModel: TreeViewModel = hiltViewModel(),
    content: @Composable (PaddingValues) -> Unit
) {
    val keyboardController = LocalSoftwareKeyboardController.current
    val query by treeViewModel.query.collectAsState()
    val isSearching by treeViewModel.isSearching.collectAsState()

    Scaffold(
        topBar = {
            Row {
                SearchBar(
                    query = query,
                    onQueryChange = {
                        treeViewModel.onQueryChanged(it)
                    },
                    onSearch = {
                        keyboardController?.hide()
                        treeViewModel.onIsSearchingChanged(false)
                    },
                    active = isSearching,
                    onActiveChange =  {
                        treeViewModel.onIsSearchingChanged(it)
                    },
                    placeholder = { Text("Search...") },
                ) {
                }

                IconButton(onClick = { /* do something */ }) {
                    Icon(Icons.Filled.Check, contentDescription = "Localized description")
                }
                IconButton(onClick = { /* do something */ }) {
                    Icon(
                        Icons.Filled.Menu,
                        contentDescription = "Localized description",
                    )
                }
            }
        },
    ) { innerPadding ->
        content(innerPadding)
    }
}

