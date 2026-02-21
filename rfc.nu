let rfc_dir = "data/rfc"
let rfc_file = $"($rfc_dir)/rfc_index.tsv"

mkdir $rfc_dir

# 既存ファイルのレコードを取得
let existing = if ($rfc_file | path exists) {
    open $rfc_file
} else {
    []
}

# 最初のリクエストで総件数を取得
let url_base = "https://datatracker.ietf.org/api/v1/doc/document/?format=json&type=rfc&limit=100"
let first_result = http get $"($url_base)&offset=0"
let total_count = $first_result.meta.total_count
let limit = 100
let pages = ($total_count / $limit | math ceil | into int)

print $"Fetching ($total_count) RFCs across ($pages) pages in parallel..."

let all_rfcs = 0..<$pages | par-each { |page|
    let objects = if $page == 0 {
        $first_result | get objects
    } else {
        http get $"($url_base)&offset=($page * $limit)" | get objects
    }
    $objects | each { |r|
        let std_level_raw = $r | get -o std_level | default ""
        let status = if ($std_level_raw | is-empty) {
            "unknown"
        } else {
            $std_level_raw | split row "/" | where { |x| not ($x | is-empty) } | last
        }
        let abstract = $r | get -o abstract | default "" | str replace --all "\n" " " | str replace --all "\t" " " | str trim | str substring ..300
        {
            rfc_number: $r.rfc,
            title: ($r.title | default ""),
            status: $status,
            abstract: $abstract,
            url: $"https://www.rfc-editor.org/rfc/rfc($r.rfc)"
        }
    }
} | flatten

# 既存データとマージ → uniq → 昇順ソート → 上書き保存
let merged = $existing | append $all_rfcs | uniq-by rfc_number | sort-by { |r| $r.rfc_number | into int }
let added = ($merged | length) - ($existing | length)

$merged | to tsv | collect | save -f $rfc_file

if $added > 0 {
    let last_num = $merged | last | get rfc_number
    print $"Added ($added) new RFCs, up to RFC ($last_num)"
} else {
    print "No new RFCs found"
}
