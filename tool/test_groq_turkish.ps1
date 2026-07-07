# Quick, throwaway check of Groq's Turkish combination quality.
#
# Sends a handful of Turkish element pairs (including ones that need
# cultural/idiomatic knowledge, not just literal translation) to the same
# Groq model the game's Edge Function uses, with a Turkish system prompt.
# Prints each result so we can judge quality before deciding whether
# Turkish needs a different LLM.
#
# Usage:
#   $env:GROQ_API_KEY = "..."
#   ./tool/test_groq_turkish.ps1

if (-not $env:GROQ_API_KEY) {
    Write-Error "GROQ_API_KEY ortam degiskenini once ayarla: `$env:GROQ_API_KEY = '...'"
    exit 1
}

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$GroqUrl = "https://api.groq.com/openai/v1/chat/completions"
$GroqModel = "llama-3.3-70b-versatile"

$promptTemplate = @'
Sen "Infinite Craft" tarzi bir oyunun birlesim motorusun. Oyuncular iki elementi birlestirerek yeni bir element kesfeder.
Birlestir: "__A__" + "__B__"

Bu iki elementin gercekci, mantiksal veya kulturel olarak neyi ortaya cikaracagini dusun (neden-sonuc iliskisi, fiziksel birlesim ya da iyi bilinen bir kavram/kulturel referans). Rastgele veya anlamsiz sonuclardan kacin.

Iyi birlesim ornekleri:
- Su + Ates -> Buhar
- Toprak + Su -> Camur
- Ates + Hava -> Duman
- Su + Toprak -> Bitki
- Ates + Toprak -> Lav

Kurallar:
- "name": 1-3 kelime, Baslik Formatinda, duzgun Turkce (gerekli yerlerde c, g, i, o, s, u harflerinin Turkce ozel hallerini kullan), gercek ve taninabilir bir isim/kavram.
- "emoji": "name"i gorsel olarak temsil eden tek bir emoji.
- Sonuc bir insana mantikli veya en azindan sezgisel gelmeli, asla sacma veya rastgele olmamali.
- Girdi isimlerinden birini, gercekten en iyi cevap degilse tekrar etme.
- Ayni girdi cifti her zaman ayni ciktiyi uretmeli (deterministik ol).
- SON CARE olarak: bu iki elementin gercekten mantikli, yaratici veya eglenceli hicbir baglantisi yoksa {"name": null, "emoji": null} dondur. Bunu nadiren kullan - once gercek/yaratici bir baglanti bulmaya calis.
Sadece su formatta JSON dondur: {"name": "...", "emoji": "..."} veya {"name": null, "emoji": null}
'@

$pairs = @(
    @("Su", "Ates"),
    @("Toprak", "Su"),
    @("Ates", "Hava"),
    @("Ates", "Kus"),
    @("Toprak", "Insan"),
    @("Zaman", "Insan"),
    @("Ruzgar", "Yaprak"),
    @("Ay", "Gece"),
    @("Kitap", "Ates"),
    @("Su", "Seker")
)

foreach ($pair in $pairs) {
    $a = $pair[0]
    $b = $pair[1]
    $prompt = $promptTemplate.Replace('__A__', $a).Replace('__B__', $b)

    $bodyObject = @{
        model            = $GroqModel
        messages         = @(@{ role = "user"; content = $prompt })
        response_format  = @{ type = "json_object" }
        temperature      = 0.4
    }
    $bodyJson = $bodyObject | ConvertTo-Json -Depth 5 -Compress
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyJson)

    try {
        $response = Invoke-RestMethod -Uri $GroqUrl -Method Post -Headers @{
            "Content-Type"  = "application/json"
            "Authorization" = "Bearer $env:GROQ_API_KEY"
        } -Body $bodyBytes

        $result = $response.choices[0].message.content | ConvertFrom-Json
        Write-Output "$a + $b -> $($result.emoji) $($result.name)"
    } catch {
        Write-Output "$a + $b -> HATA: $_"
    }
}
