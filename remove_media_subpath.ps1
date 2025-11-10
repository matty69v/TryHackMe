# Script pour supprimer media_subpath des posts

$postsFolder = "C:\Users\bezet\OneDrive - INSTITUTION CHARTREUX\TryHackMe\_posts"

Get-ChildItem -Path $postsFolder -Filter "*.md" | ForEach-Object {
    $filePath = $_.FullName
    $fileName = $_.Name
    
    # Lire le contenu
    $content = Get-Content -Path $filePath -Raw
    
    # Vérifier si media_subpath existe
    if ($content -match 'media_subpath:') {
        # Supprimer la ligne media_subpath
        $content = $content -replace '\nmedia_subpath:[^\n]*\n', "`n"
        
        # Écrire le contenu modifié
        Set-Content -Path $filePath -Value $content -NoNewline -Encoding UTF8
        
        Write-Host "✅ media_subpath supprimé de $fileName" -ForegroundColor Green
    } else {
        Write-Host "⏭️  Pas de media_subpath dans $fileName" -ForegroundColor Yellow
    }
}

Write-Host "`n✨ Nettoyage terminé !" -ForegroundColor Cyan
