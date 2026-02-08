# Disko sur Microsoft Windows

## skribprotekto

```bash
Get-Disk 
Set-Disk -Number {diskonumero} -IsReadOnly $false
Get-Disk -Number {diskonumero} # atendata rezulto : IsReadOnly=false
```

```bash
Get-Volume
Set-Volume -DriveLetter {volumennumero} -IsReadOnly $false
Get-Disk -Number {diskonumero} # atendata rezulto : IsReadOnly=false
```

```bash
diskpart
list disk
select disk X
attributes disk clear readonly
exit
```