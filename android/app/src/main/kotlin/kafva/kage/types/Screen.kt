package kafva.kage.types

sealed interface Screen {
    val route: String

    data object Home : Screen {
        override val route = "Home"
    }

    data object Settings : Screen {
        override val route = "Settings"
    }

    data object History : Screen {
        override val route = "History"
    }
}

