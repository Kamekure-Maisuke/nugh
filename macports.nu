let filename = (date now | format date "%Y%m%d") + "_macports_trend.tsv"

mkdir data/macports

http get "https://ports.macports.org/api/v1/statistics/popular/?days=30&limit=100"
| sort-by total_count --reverse
| to tsv
| save -f $"data/macports/($filename)"
