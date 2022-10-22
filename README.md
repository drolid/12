#### <i> Odroid M1 - Debian 12/Bookworm Debootstrap </i>

<br/>

```
prepare, format and mount the destination partition - nvme   
bootstrap.sh <mountpoint>
    
example:   
    sudo su
    mkfs.ext4 /dev/nvme0n1p4  
    mount /dev/nvme0n1p4 /mnt/dst
    ./bootstrap.sh /mnt/dst

```


