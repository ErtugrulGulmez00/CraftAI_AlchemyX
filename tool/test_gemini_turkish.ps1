# Quick, throwaway check of Gemini's Turkish combination quality.
#
# Sends the same Turkish element pairs used in test_groq_turkish.ps1 to
# Gemini 1.5 Flash, with the same Turkish system prompt, so the two models'
# results can be compared side by side before deciding which one to use
# for the Turkish version of the game.
#
# Usage:
#   $env:GEMINI_API_KEY = "..."
#   ./tool/test_gemini_turkish.ps1

if (-not $env:GEMINI_API_KEY) {
    Write-Error "GEMINI_API_KEY ortam degiskenini once ayarla: `$env:GEMINI_API_KEY = '...'"
    exit 1
}

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$GeminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$($env:GEMINI_API_KEY)"

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
- Girdi isimlerinden birini, gercekten en iyi cevap degilse tekrar etme. Iki girdiyi yan yana yazip yeni isim gibi sunmak YASAK (ornek: "Ay" + "Gece" icin "Ay Gece" KABUL EDILEMEZ; "Ay Isigi" gibi tek bir kavram olmali).
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
        contents = @(
            @{
                role  = "user"
                parts = @(@{ text = $prompt })
            }
        )
        generationConfig = @{
            temperature      = 0.4
            responseMimeType = "application/json"
        }
    }
    $bodyJson = $bodyObject | ConvertTo-Json -Depth 6 -Compress
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyJson)

    # Free tier kotasi cok dar ve modeli zaman zaman asiri yuklenmis donuyor
    # (503/429) - art arda denemeden once kisa bir bekleme + bir kez yeniden
    # deneme ile bu gecici hatalarin onunu aliyoruz.
    $attempt = 0
    $done = $false
    while (-not $done -and $attempt -lt 3) {
        $attempt++
        try {
            $response = Invoke-RestMethod -Uri $GeminiUrl -Method Post -Headers @{
                "Content-Type" = "application/json"
            } -Body $bodyBytes

            $text = $response.candidates[0].content.parts[0].text
            $result = $text | ConvertFrom-Json
            Write-Output "$a + $b -> $($result.emoji) $($result.name)"
            $done = $true
        } catch {
            if ($attempt -ge 3) {
                Write-Output "$a + $b -> HATA: $_"
            } else {
                Start-Sleep -Seconds 8
            }
        }
    }

    Start-Sleep -Seconds 5
}
