# Knowledge Base

## Tenant Migration

### MFA Sign-Up Errors After Migrating a Custom Domain Name

When a source tenant custom domain name is removed and assigned to a destination tenant, there will be a 24-hr window in which an attempted MFA registration will return a JSON Bad Request (400) message. After 24hrs the MFA signup page will function as normal. This appears to be due to Azure cacheing the previous UPN's association with the source tenant.



