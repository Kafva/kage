package one.kafva.kage.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import one.kafva.kage.BODY_FONT_SIZE
import one.kafva.kage.CONTAINER_MODIFIER
import one.kafva.kage.CORNER_RADIUS
import one.kafva.kage.FOOTNOTE_FONT_SIZE
import one.kafva.kage.data.GitRepository
import one.kafva.kage.types.CommitInfo
import javax.inject.Inject

@HiltViewModel
class HistoryViewModel
    @Inject
    constructor(
        val gitRepository: GitRepository,
    ) : ViewModel()

@Composable
fun HistoryView(viewModel: HistoryViewModel = hiltViewModel()) {
    val expandEntry: MutableState<String?> = remember { mutableStateOf(null) }

    LazyColumn(modifier = CONTAINER_MODIFIER) {
        viewModel.gitRepository.log().forEach { log ->
            item {
                if (log.revision == expandEntry.value) {
                    ExpandedEntryView(log, expandEntry)
                } else {
                    EntryView(log, expandEntry)
                }
            }
        }
    }
}

@Composable
private fun ExpandedEntryView(
    log: CommitInfo,
    expandEntry: MutableState<String?>,
) {
    ListItem(
        headlineContent = {
            Text(
                text = log.summary,
                fontSize = BODY_FONT_SIZE.sp,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
        },
        supportingContent = {
            Column {
                Text(
                    log.date,
                    fontSize = FOOTNOTE_FONT_SIZE.sp,
                    color = MaterialTheme.colorScheme.outline,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    log.revision,
                    fontSize = FOOTNOTE_FONT_SIZE.sp,
                    color = MaterialTheme.colorScheme.outline,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        },
        modifier =
            Modifier
                .height(200.dp)
                .padding(
                    bottom = 10.dp,
                ).clip(RoundedCornerShape(CORNER_RADIUS))
                .clickable(true) {
                    expandEntry.value = null
                },
        colors =
            ListItemDefaults.colors(
                containerColor =
                    MaterialTheme.colorScheme.surfaceContainer,
            ),
    )
}

@Composable
private fun EntryView(
    log: CommitInfo,
    expandEntry: MutableState<String?>,
) {
    ListItem(
        headlineContent = {
            Text(
                text = log.summary,
                fontSize = BODY_FONT_SIZE.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        },
        leadingContent = {
            Text(
                log.date,
                fontSize = FOOTNOTE_FONT_SIZE.sp,
                color = MaterialTheme.colorScheme.outline,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        },
        modifier =
            Modifier
                .padding(
                    bottom = 10.dp,
                ).clip(RoundedCornerShape(CORNER_RADIUS))
                .clickable(true) {
                    expandEntry.value = log.revision
                },
        colors =
            ListItemDefaults.colors(
                containerColor =
                    MaterialTheme.colorScheme.surfaceContainer,
            ),
    )
}
