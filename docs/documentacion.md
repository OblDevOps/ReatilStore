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
### Justificacion


Decidimos implementar **GitLab Flow** basándonos en nuestra experiencia previa con GitFlow en el proyecto integrador. Si bien esa metodología resultó muy útil en su momento, consideramos que para un desarrollo de corta duración y sin continuidad a largo plazo, su estructura genera una sobrecarga innecesaria. 

Por este motivo, optamos por esta alternativa de ramificación: un enfoque menos exigente que reduce los pasos intermedios, pero que mantiene un nivel de orden y organización muy similar. Esto permitió que la adaptación del equipo fuera más ágil y eficiente, optimizando los tiempos de trabajo sin perder el control del flujo de desarrollo.

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
