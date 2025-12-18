#!/bin/bash

# 📌 Dossier contenant les dépôts Git
REPO_DIR="/chemin/vers/tes/repos"

# 📅 Vérifier si un pull a déjà été fait aujourd'hui
LAST_RUN_FILE="/tmp/last_git_pull"
CURRENT_DATE=$(date +"%Y-%m-%d")

if [[ -f "$LAST_RUN_FILE" && $(cat "$LAST_RUN_FILE") == "$CURRENT_DATE" ]]; then
    # Optionnel : log pour dire que c'est déjà fait, mais on évite la notif pour ne pas spammer
    exit 0
fi

echo "$CURRENT_DATE" > "$LAST_RUN_FILE"

# 🔄 Exécuter les pulls
if cd "$REPO_DIR"; then
    for repo in */; do
        # On vérifie si c'est bien un dépôt git
        if [[ -d "$repo/.git" ]]; then
            echo "📂 Traitement de : $repo"
            
            # On utilise ( ... ) pour isoler le changement de dossier.
            # Plus besoin de faire "cd .." à la fin.
            (
                cd "$repo" || exit
                
                # SÉCURITÉ : On stash les changements locaux au lieu de reset --hard
                STASHED=0
                if [[ -n $(git status --porcelain) ]]; then
                    echo "   ⚠️  Changements locaux détectés -> Sauvegarde (Stash)..."
                    git stash
                    STASHED=1
                fi

                # Tentative de pull
                if git pull; then
                    echo "   ✅ Mise à jour réussie."
                else
                    echo "   ❌ Échec du pull."
                fi

                # Si on avait stashé, on tente de réappliquer les modifs
                if [[ $STASHED -eq 1 ]]; then
                    echo "   🔄 Restauration des changements locaux..."
                    git stash pop
                fi
            )
        fi
    done
else
    echo "❌ Erreur : Impossible d'accéder au dossier $REPO_DIR"
    exit 1
fi

# 🔔 Notification de fin (macOS uniquement)
osascript -e 'display notification "Tous les dépôts ont été mis à jour." with title "Git Pull Automatique"'
