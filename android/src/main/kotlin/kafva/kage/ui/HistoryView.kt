package kafva.kage.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import kafva.kage.G
import kafva.kage.data.GitRepository
import javax.inject.Inject

@HiltViewModel
class HistoryViewModel
    @Inject
    constructor(
        val gitRepository: GitRepository,
    ) : ViewModel()

@Composable
fun HistoryView(viewModel: HistoryViewModel = hiltViewModel()) {
    LazyColumn(modifier = G.containerModifier) {
        viewModel.gitRepository.log().forEach { log ->
            item {
                ListItem(
                    headlineContent = {
                        Text(
                            text = log.summary,
                            fontSize = G.BODY_FONT_SIZE.sp,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    },
                    leadingContent = {
                        Text(
                            log.date,
                            fontSize = G.FOOTNOTE_FONT_SIZE.sp,
                            color = MaterialTheme.colorScheme.outline,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    },
                    modifier =
                        Modifier
                            .padding(
                                bottom = 10.dp,
                            ).clip(RoundedCornerShape(50)),
                    colors =
                        ListItemDefaults.colors(
                            containerColor =
                                MaterialTheme.colorScheme.surfaceContainer,
                        ),
                )
            }
        }
    }
}
