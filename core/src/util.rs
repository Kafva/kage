use crate::log;

pub fn path_to_filename(pathstr: &str) -> Option<&str> {
    let path = std::path::Path::new(pathstr);

    if let Some(filename) = path.file_name() {
        return filename.to_str();
    }

    error!("Bad filepath: '{}'", pathstr);
    None
}
