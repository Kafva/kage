package kafva.kage.ui.views

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.shape.RoundedCornerShape
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
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.KeyboardArrowLeft
import androidx.compose.material3.BottomAppBarDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.SearchBar
import androidx.compose.material3.TextField
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.Color
import androidx.hilt.navigation.compose.hiltViewModel
import kafva.kage.data.TreeViewModel
import androidx.compose.ui.unit.dp
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.Alignment
import androidx.navigation.compose.rememberNavController
import androidx.navigation.compose.currentBackStackEntryAsState
import kafva.kage.types.Screen
import androidx.navigation.NavHostController

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ToolbarView(
    navController: NavHostController,
    treeViewModel: TreeViewModel = hiltViewModel(),
    content: @Composable (PaddingValues) -> Unit
) {
    val expandRecursively by treeViewModel.expandRecursively.collectAsState()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route ?: Screen.Home.route

    Scaffold(
        topBar = {
            Row(modifier = Modifier.padding(top = 30.dp).fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center) {

                when (currentRoute) {
                    Screen.Home.route -> {
                        SearchField()

                        IconButton(onClick = {
                            treeViewModel.expandRecursively.value =
                                !treeViewModel.expandRecursively.value
                        }) {
                            val treeExpansionIcon = if (expandRecursively)
                                            Icons.Filled.KeyboardArrowDown
                                       else Icons.Filled.KeyboardArrowRight
                            Icon(treeExpansionIcon, "Toggle tree expansion")
                        }

                        IconButton(onClick = {
                            navController.navigate(Screen.Settings.route)
                        }) {
                            Icon(Icons.Filled.Settings, "Settings")
                        }
                    }
                    else -> {
                        IconButton(onClick = {
                            navController.navigate(Screen.Home.route)

                        }) {
                            Icon(Icons.Filled.KeyboardArrowLeft, "Go home")
                        }
                        Text(currentRoute)
                    }
                }


            }
        },

    ) { innerPadding ->
        content(innerPadding)
    }
}

@Composable
private fun SearchField(treeViewModel: TreeViewModel = hiltViewModel()) {
    val focusManager = LocalFocusManager.current
    val query by treeViewModel.query.collectAsState()

    TextField(
        value = query,
        onValueChange = {
            treeViewModel.onQueryChanged(it)
        },
        placeholder = { Text("Search...") },
        singleLine = true,
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
        keyboardActions = KeyboardActions(
            onDone = {
                focusManager.clearFocus()
            }
        ),
    )
}
