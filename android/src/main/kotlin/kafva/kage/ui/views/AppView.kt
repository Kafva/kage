package kafva.kage.ui.views

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
import kafva.kage.ui.theme.KageTheme
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.lifecycle.compose.LocalLifecycleOwner

import androidx.navigation.compose.NavHost
import androidx.navigation.NavHostController
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.compose.currentBackStackEntryAsState
import kafva.kage.Log
import kafva.kage.types.Screen
import kafva.kage.ui.views.SettingsView
import kafva.kage.ui.views.HistoryView
import kafva.kage.ui.views.TreeView
import kafva.kage.ui.views.ToolbarView
import kafva.kage.data.AppViewModel
import java.time.Instant

@Composable
fun AppView(
    navController: NavHostController = rememberNavController(),
    viewModel: AppViewModel = hiltViewModel()
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route ?: Screen.Home.route
    val identityUnlockedAt = viewModel.appRepository.identityUnlockedAt.collectAsState()
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
                        val filesDir = "${viewModel.appRepository.filesDir.path}/"
                        val nodePath = node.pathString.removePrefix(filesDir).replace("/", "|")
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
                composable("${Screen.Password.route}/{nodePath}") { nodePath ->
                    // TODO better error handling?
                    val argument = navBackStackEntry?.arguments?.getString("nodePath") ?: ""
                    PasswordView(argument)
                }
            }
        }
    }

    LaunchedEffect(lifecycleState) {
        Log.i("State change: $lifecycleState")

        if (identityUnlockedAt.value != null) {
            val distance = Instant.now().epochSecond - (identityUnlockedAt.value ?: 0)
            if (distance >= 2*60) {
                viewModel.appRepository.lockIdentity()
                Log.i("Locked identity due to timeout")
            }
        }
    }
}
