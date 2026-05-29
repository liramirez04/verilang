// TODO: si renombraste el paquete, cambia "milang" por el nombre de tu lenguaje
package milang

import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberWindowState
import milang.ui.MainWindow

fun main() = application {
    Window(
        onCloseRequest = ::exitApplication,
        title = "VeriLang",
        state = rememberWindowState(width = 800.dp, height = 600.dp)
    ) {
        MainWindow()
    }
}
