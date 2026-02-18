let since = (date now) - 4wk | format date "%Y-%m-%d"
let filename = (date now | format date "%Y%m%d") + "_gh_trend.tsv"

let languages = ["javascript", "typescript", "python", "go"]

for lang in $languages {
    mkdir $"data/($lang)"
    let url = $"https://api.github.com/search/repositories?q=created:%3E($since)+language:($lang)&sort=stars&order=desc&per_page=10"
    http get $url | get items | select name stargazers_count html_url
    | to tsv
    | save $"data/($lang)/($filename)"
}
