let since = (date now) - 4wk | format date "%Y-%m-%d"
let filename = (date now | format date "%Y%m%d") + "_gh_trend_noai.tsv"

let language = "go"
let ai_keywords = ["llm", "gpt", "chatgpt", "openai", "gemini",
                   "claude", "copilot", "agent", "rag",
                   "neural", "diffusion", "transformer", "deepseek",
                   "mistral", "ollama", "mcp", "qwen", "glm", "sora", "asr", "openclaw", "anthropic"]

let repos = 1..5 | each { |page|
    let url = $"https://api.github.com/search/repositories?q=created:%3E($since)+language:($language)&sort=stars&order=desc&per_page=100&page=($page)"
    http get $url | get items
} | flatten

let filtered = $repos | where { |repo|
    let text = ([$repo.name ($repo.description? | default "")] | str join " " | str downcase)
    let topics = ($repo.topics | str join " " | str downcase)
    let keyword_match = $ai_keywords | any { |kw| ($text | str contains $kw) or ($topics | str contains $kw) }
    let ai_word_match = ($text =~ '\bai\b') or ($topics =~ '\bai\b')
    not ($keyword_match or $ai_word_match)
}

mkdir $"data/($language)"
$filtered | select name stargazers_count html_url | first 10 | to tsv | save -f $"data/($language)/($filename)"
