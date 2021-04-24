# Exchange Online

## Recipients

### Get-IAEXORecipientsAsDictionary

Retrives all recipients and their size (where a mailbox).

```powershell
<#
    .SYNOPSIS
    Retrives all recipients on the connected Exchange Online environment.

    .DESCRIPTION
    All returned recipients will be grouped by their type.

    ie. Where Exchange Online contains Room Mailboxes, Mail Users and User Mailboxes;
    You will see an object returned with these keys.

    .EXAMPLE
    $Results = Get-IAEXORecipientsAsDictionary
    $Results

    Key                            Value
    ---                            -----
    UserMailbox                    IARecipients
    RoomMailbox                    IARecipients
    MailUsers                      IARecipients

    $Results['UserMailbox']


    CombinedSizeInGB Recipients
    ---------------- ----------
    725.87           {@{ExternalDirectoryObjectId=....


    $Results['UserMailbox'].Recipients

    ...
    ExternalDirectoryObjectId :
    Identity                  : Chris Dymond
    Alias                     : Chris.Dymond
    EmailAddresses            : {SPO:SIP:SMTP.mail.onmicrosoft.com...}
    DisplayName               : Chris Dymond
    Name                      : Chris Dymond
    PrimarySmtpAddress        : Chris.Dymond@domain.com
    RecipientType             : UserMailbox
    RecipientTypeDetails      : UserMailbox
    ExchangeVersion           : 0.20 (15.0.0.0)
    DistinguishedName         : CN=
    OrganizationId            :
    TotalItemSize             : 1.243 GB (1,334,578,302 bytes)
    TotalItemSizeInGB         : 1.24
    ...

    .NOTES

    #>
```

### Get-IAEXORecipientsOnMicrosoft

Retrieve's all recipients with an @something.onmicrosoft.com proxy address.

```powershell
    <#
    .SYNOPSIS
    Returns all recipients with the @tenant.onmicrosoft.com suffix.

    .DESCRIPTION
    All recipients matching onmicrosoft.com are returned as a List.

    .EXAMPLE
    $Results = Get-IAEXORecipientsOnMicrosoft
    $Results

    ...
    ExternalDirectoryObjectId : ...
    Identity                  : Chris Dymond
    Alias                     : Chris.Dymond
    EmailAddresses            : {SPO:SIP:SMTP.mail.onmicrosoft.com...}
    DisplayName               : Chris Dymond
    Name                      : Chris Dymond
    PrimarySmtpAddress        : Chris.Dymond@domain.com
    RecipientType             : UserMailbox
    RecipientTypeDetails      : UserMailbox
    ExchangeVersion           : 0.20 (15.0.0.0)
    DistinguishedName         : CN=...
    OrganizationId            : ...
    ...

    .NOTES

    #>
```
