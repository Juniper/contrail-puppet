class contrail::tsn() {
    contrail::lib::report_status { "tsn_started": state => "tsn_started" }
    -> notify{ "**** $module_name : TSN Role":;}
    -> contrail::lib::report_status { "tsn_completed": state => "tsn_completed" }
}
