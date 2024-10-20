package kafva.kage.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import dagger.hilt.android.AndroidEntryPoint
import dagger.hilt.android.lifecycle.HiltViewModel
import kafva.kage.ui.theme.KageTheme
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.tooling.preview.Preview
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.ViewModel

import androidx.navigation.compose.NavHost
import androidx.navigation.NavHostController
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.compose.currentBackStackEntryAsState
import kafva.kage.Log
import kafva.kage.data.AgeRepository
import kafva.kage.data.AppRepository
import kafva.kage.types.Screen
import kafva.kage.ui.SettingsView
import kafva.kage.ui.HistoryView
import kafva.kage.ui.TreeView
import kafva.kage.ui.ToolbarView
import java.time.Instant
import javax.inject.Inject

@HiltViewModel
class AppViewModel @Inject constructor(
    val appRepository: AppRepository,
    val ageRepository: AgeRepository,
) : ViewModel() {}

@Composable
fun AppView(
    navController: NavHostController = rememberNavController(),
    viewModel: AppViewModel = hiltViewModel()
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route ?: Screen.Home.route
    val lifecycleOwner = LocalLifecycleOwner.current
    val lifecycleState by lifecycleOwner.lifecycle.currentStateFlow.collectAsState()

    ToolbarView(currentRoute,
        { navController.navigate(Screen.Settings.route) },
        { navController.popBackStack() },
    ) { innerPadding ->
        Column(
            modifier = Modifier.fillMaxSize()
                               .background(MaterialTheme.colorScheme.surface)
                               .padding(innerPadding),
            verticalArrangement = Arrangement.spacedBy(10.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            NavHost(navController = navController, Screen.Home.route) {
                composable(Screen.Home.route) {
                    TreeView({ node ->
                        val nodePath = node.toRoutePath(viewModel.appRepository.filesDir)
                        navController.navigate("${Screen.Password.route}/${nodePath}")
                    })
                }
                composable(Screen.Settings.route) {
                    SettingsView(
                        { navController.navigate(Screen.History.route) },
                    )
                }
                composable(Screen.History.route) {
                    HistoryView()
                }
                composable("${Screen.Password.route}/{nodePath}") { _ ->
                    val argument = navBackStackEntry?.arguments?.getString("nodePath")
                    if (argument != null) {
                        PasswordView(argument)
                    }
                }
            }
        }
    }

    LaunchedEffect(lifecycleState) {
        viewModel.ageRepository.onStateChange(lifecycleState)
    }
}