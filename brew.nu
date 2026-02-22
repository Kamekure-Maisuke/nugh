let filename = (date now | format date "%Y%m%d") + "_brew_trend.tsv"

mkdir data/brew

http get "https://formulae.brew.sh/api/analytics/install/homebrew-core/30d.json"
| get formulae
| values
| flatten
| update count { str replace --all ',' '' | into int }
| sort-by count --reverse
| first 100
| to tsv
| save -f $"data/brew/($filename)"
