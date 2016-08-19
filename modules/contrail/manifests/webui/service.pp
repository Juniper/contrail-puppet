class contrail::webui::service() {
    service { 'supervisor-webui' :
        ensure    => running,
        enable    => true,
    }
}
