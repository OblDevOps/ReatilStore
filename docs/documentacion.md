# Documentación — RetailStore DevOps

**Materia:**  DevOps  
**Universidad:** ORT Uruguay  

| Integrante | Número de estudiante |
|---|---|
| Joaquín Gil | 322300 |
| Joaquín Pardiñas | 323279 |
| Mateo González | 323444 |

---

## Estrategia de ramas

Se utilizó **GitLab Flow** con las siguientes ramas permanentes:

| Rama | Descripción |
|---|---|
| `main` | Rama principal, representa Prod |
| `develop` | Rama de integración, representa Dev y Test |
| `feature/*` | Ramas de vida corta para cada tarea |

El flujo de trabajo es:
```
feature/* → develop → main
```

---

## Ambientes

| Ambiente | Rama | Deploy |
|---|---|---|
| Dev | `develop` | Automático |
| Test | `develop` | Automático (tras quality gate) |
| Prod | `main` | Aprobación manual requerida |

---

## Gestión del proyecto

### Tablero Kanban

#### Inicio
![Kanban inicio](./img/tablero-inicio.png)

#### Mitad
_Pendiente_

#### Cierre
_Pendiente_