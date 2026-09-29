# az-lab
Azure lab infrastructure

This is a Azure lab infrastructure created to simulate an IT multi-team envrionment where IT Ops manages the subscription as an owner.

Team structure:
- IT Operations (itops) - Platform admin team
- Artificial Intelligence (ai)
- Software Engineering (swe)
- Security (sec)
- DevOps (devops)
- Multi team (common): [shared resources]

Azure RBAC table:
| Team   | Subscription | Shared      | Own Resource Group | Other Teams |
| ------ | ------------ | ------      | ------------------ | ----------- |
| IT Ops | owner        | owner       | owner              | owner       |
| AI     | reader       | contributor | owner              | reader      |
| SWE    | reader       | contributor | owner              | reader      |
| DevOps | contributor  | contributor | owner              | contributor |
| Sec    | contributor  | contributor | owner              | contributor |


Tagging:
- team (team)
- envrionment (env)
- project (proj)
