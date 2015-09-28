# export all AD-users
# il faut installer le module active directory sur Windows server 2008
# Importer le module sur Windows Server 2012 R2
# lancer le script sur un dc

# rechercher un utilisateur dans la base active directory

function find_userad()
{
    $inp_name = Read-Host "Veuillez indiquer un utilisateur de la base AD"

    $username = Get-ADUser -Filter {samAccountName -eq $inp_name}

    if (!username)
    {

	   Write-error "Cet utilisateur n'\existe pas"
    }
    else
    {
 	  Write-Host "$inp_name existe"
    
    }

}
