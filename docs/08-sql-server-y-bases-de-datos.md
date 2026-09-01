# 08 — SQL Server y otras bases de datos

> Objetivo: tener SQL Server corriendo en tu Arch, con clientes gráficos y de terminal,
> conectado desde .NET, Python, Java, PHP y Node.

---

## 1. Por qué en contenedor

Microsoft distribuye SQL Server para Linux solo como paquetes de RHEL, Ubuntu y SLES. En
Arch, instalarlo nativamente significaría pelear con `glibc`, rutas y dependencias. La vía
soportada y limpia es **Docker**:

- Se instala en un comando y se borra en otro.
- Puedes tener SQL Server 2019, 2022 y 2025 a la vez, en puertos distintos.
- No ensucia tu sistema con librerías ajenas a Arch.
- Es exactamente cómo se despliega en producción hoy.

## 2. Levantar SQL Server

Requisitos: Docker funcionando (doc 07, sección 8) y al menos **2 GB de RAM libres**.

### Con `docker compose` (recomendado)

Crea `~/dev/infra/docker-compose.yml`:

```bash
mkdir -p ~/dev/infra && cd ~/dev/infra
```

```yaml
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: sqlserver
    hostname: sqlserver
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: "${MSSQL_SA_PASSWORD:?define MSSQL_SA_PASSWORD en .env}"
      MSSQL_PID: "Developer"      # edición gratuita para desarrollo
      TZ: "America/Santiago"
    ports:
      - "127.0.0.1:1433:1433"     # solo accesible desde tu máquina
    volumes:
      - mssql-data:/var/opt/mssql
      - ./backups:/var/opt/mssql/backups
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL",
             "/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P \"$$MSSQL_SA_PASSWORD\" -C -Q 'SELECT 1' || exit 1"]
      interval: 15s
      timeout: 5s
      retries: 10
      start_period: 30s

volumes:
  mssql-data:
```

Y el archivo de secretos:

```bash
cat > ~/dev/infra/.env <<'ENV'
MSSQL_SA_PASSWORD=Dev_Str0ng!Pass2026
ENV
chmod 600 ~/dev/infra/.env
echo ".env" >> ~/dev/infra/.gitignore
mkdir -p ~/dev/infra/backups
```

⚠️ **Requisitos de la contraseña de `sa`:** mínimo 8 caracteres, con mayúsculas, minúsculas,
números y símbolos. Si no los cumple, el contenedor arranca y se apaga en 2 segundos —
es la causa #1 de "no me funciona".

⚠️ **Nunca subas el `.env` a Git.** Por eso el `.gitignore`.

Levántalo:

```bash
cd ~/dev/infra
docker compose up -d
docker compose ps
docker compose logs -f sqlserver     # Ctrl+C para salir
```

Cuando veas `SQL Server is now ready for client connections`, está listo.

💡 `ports: "127.0.0.1:1433:1433"` ata el puerto solo a localhost. Si pusieras `"1433:1433"`,
Docker abriría el puerto a toda tu red **saltándose ufw** (Docker manipula iptables
directamente). Este detalle evita exponer tu base de datos en un café.

### Comandos del día a día

```bash
docker compose up -d          # levantar
docker compose stop           # parar (conserva los datos)
docker compose start          # volver a arrancar
docker compose restart sqlserver
docker compose logs --tail 50 sqlserver
docker compose down           # parar y borrar contenedores (los datos siguen en el volumen)
docker compose down -v        # ⚠️ borra TAMBIÉN los datos
```

## 3. Cliente de terminal: `sqlcmd`

### Opción A — usar el que ya viene en el contenedor

```bash
docker exec -it sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'Dev_Str0ng!Pass2026' -C
```

`-C` confía en el certificado autofirmado del contenedor (necesario en desarrollo).

Dentro del prompt `1>`:

```sql
SELECT @@VERSION;
GO

CREATE DATABASE Inventario;
GO

USE Inventario;
GO

CREATE TABLE Productos (
    Id      INT IDENTITY PRIMARY KEY,
    Nombre  NVARCHAR(120) NOT NULL,
    Precio  DECIMAL(10,2) NOT NULL,
    Stock   INT NOT NULL DEFAULT 0
);
GO

INSERT INTO Productos (Nombre, Precio, Stock) VALUES
  (N'Teclado mecánico', 79990, 12),
  (N'Monitor 27"',      249990, 4);
GO

SELECT * FROM Productos;
GO

EXIT
```

💡 `GO` no es SQL: es el separador de lotes de las herramientas de Microsoft. Sin él, nada
se ejecuta.

### Opción B — instalar `sqlcmd` en el host (más cómodo)

```bash
paru -S msodbcsql18 mssql-tools18
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.zshrc
source ~/.zshrc

sqlcmd -S localhost,1433 -U sa -P 'Dev_Str0ng!Pass2026' -C -Q "SELECT name FROM sys.databases"
```

Un alias práctico en `~/.zshrc`:

```bash
alias sql='sqlcmd -S localhost,1433 -U sa -P "$MSSQL_SA_PASSWORD" -C'
```

## 4. Clientes gráficos

```bash
# DBeaver — universal (SQL Server, PostgreSQL, MySQL, SQLite, Oracle...)
sudo pacman -S --needed dbeaver

# Azure Data Studio — el sucesor de SSMS, específico de Microsoft
paru -S azuredatastudio-bin

# Beekeeper Studio — ligero y bonito
paru -S beekeeper-studio-bin
```

**Configurar la conexión en DBeaver:**
Nueva conexión → SQL Server → Host `localhost`, Puerto `1433`, Usuario `sa`, contraseña la
tuya → pestaña **Driver properties** → pon `trustServerCertificate` = `true` → Test Connection.

⚠️ Si olvidas `trustServerCertificate`, verás el error
*"The driver could not establish a secure connection... PKIX path building failed"*. Es el
segundo error más común.

**En VS Code:** la extensión `ms-mssql.mssql` te da explorador de bases de datos e
IntelliSense de T-SQL sin salir del editor (`Ctrl+Shift+P` → "MS SQL: Connect").

## 5. Conectar desde cada lenguaje

La cadena de conexión base:

```
Server=localhost,1433;Database=Inventario;User Id=sa;Password=***;TrustServerCertificate=True;Encrypt=True
```

### .NET 10 (C#)

```bash
cd ~/dev/InventarioApi
dotnet add package Microsoft.Data.SqlClient
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Design
```

```csharp
using Microsoft.Data.SqlClient;

var cs = builder.Configuration.GetConnectionString("Default");
await using var conn = new SqlConnection(cs);
await conn.OpenAsync();
await using var cmd = new SqlCommand("SELECT Id, Nombre, Precio FROM Productos", conn);
await using var r = await cmd.ExecuteReaderAsync();
while (await r.ReadAsync())
    Console.WriteLine($"{r.GetInt32(0)} · {r.GetString(1)} · {r.GetDecimal(2):C}");
```

Con Entity Framework Core:

```csharp
builder.Services.AddDbContext<AppDbContext>(o =>
    o.UseSqlServer(builder.Configuration.GetConnectionString("Default")));
```

```bash
dotnet ef migrations add InicialInventario
dotnet ef database update
```

Recuerda guardar la cadena con `dotnet user-secrets` (doc 07), no en `appsettings.json`.

### Python

```bash
source .venv/bin/activate
pip install pyodbc sqlalchemy
# necesita el driver ODBC del host:
paru -S msodbcsql18
```

```python
import pyodbc, os

cs = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=localhost,1433;DATABASE=Inventario;"
    f"UID=sa;PWD={os.environ['MSSQL_SA_PASSWORD']};"
    "TrustServerCertificate=yes;"
)
with pyodbc.connect(cs) as conn:
    for row in conn.cursor().execute("SELECT Nombre, Precio FROM Productos"):
        print(row.Nombre, row.Precio)
```

### Java

`pom.xml`:

```xml
<dependency>
  <groupId>com.microsoft.sqlserver</groupId>
  <artifactId>mssql-jdbc</artifactId>
  <version>12.8.1.jre11</version>
</dependency>
```

```java
String url = "jdbc:sqlserver://localhost:1433;databaseName=Inventario;"
           + "encrypt=true;trustServerCertificate=true";
try (Connection c = DriverManager.getConnection(url, "sa", System.getenv("MSSQL_SA_PASSWORD"));
     ResultSet rs = c.createStatement().executeQuery("SELECT Nombre FROM Productos")) {
    while (rs.next()) System.out.println(rs.getString("Nombre"));
}
```

### PHP

Requiere `sqlsrv`/`pdo_sqlsrv` (doc 07, sección 4).

```php
<?php
$dsn = "sqlsrv:Server=localhost,1433;Database=Inventario;TrustServerCertificate=true";
$pdo = new PDO($dsn, 'sa', getenv('MSSQL_SA_PASSWORD'), [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
]);
foreach ($pdo->query('SELECT Nombre, Precio FROM Productos') as $fila) {
    echo "{$fila['Nombre']} — {$fila['Precio']}\n";
}
```

### Node.js

```bash
pnpm add mssql
```

```js
import sql from 'mssql';

const pool = await sql.connect({
  server: 'localhost', port: 1433,
  user: 'sa', password: process.env.MSSQL_SA_PASSWORD,
  database: 'Inventario',
  options: { encrypt: true, trustServerCertificate: true },
});
const { recordset } = await pool.request().query('SELECT Nombre, Precio FROM Productos');
console.table(recordset);
await pool.close();
```

## 6. Respaldos y restauración

### Backup

```bash
docker exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C \
  -Q "BACKUP DATABASE Inventario TO DISK='/var/opt/mssql/backups/Inventario.bak' WITH FORMAT, INIT, COMPRESSION"
```

El archivo aparece en `~/dev/infra/backups/Inventario.bak` gracias al volumen montado.

### Restauración

```bash
docker exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C \
  -Q "RESTORE DATABASE Inventario FROM DISK='/var/opt/mssql/backups/Inventario.bak' WITH REPLACE"
```

💡 Si el `.bak` viene de un SQL Server de Windows, las rutas internas de los archivos no
existirán en Linux. Usa `RESTORE FILELISTONLY` para ver los nombres lógicos y luego
`WITH MOVE 'nombre_logico' TO '/var/opt/mssql/data/archivo.mdf'`.

## 7. Otras bases de datos (por si acaso)

Añade al mismo `docker-compose.yml`:

```yaml
  postgres:
    image: postgres:17-alpine
    environment:
      POSTGRES_PASSWORD: "${PG_PASSWORD:?}"
      POSTGRES_DB: appdb
    ports: ["127.0.0.1:5432:5432"]
    volumes: ["pg-data:/var/lib/postgresql/data"]
    restart: unless-stopped

  mysql:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: "${MYSQL_PASSWORD:?}"
      MYSQL_DATABASE: appdb
    ports: ["127.0.0.1:3306:3306"]
    volumes: ["mysql-data:/var/lib/mysql"]
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    ports: ["127.0.0.1:6379:6379"]
    restart: unless-stopped

volumes:
  mssql-data:
  pg-data:
  mysql-data:
```

Clientes nativos si los prefieres al contenedor:

```bash
sudo pacman -S --needed postgresql-libs mariadb-clients redis sqlite
```

## 8. Que no arranque todo al encender la máquina

`restart: unless-stopped` hace que los contenedores vuelvan solos al reiniciar. Si prefieres
levantarlos a mano (menos RAM consumida al arrancar), quita esa línea y usa alias:

```bash
# ~/.zshrc
alias db-up='docker compose -f ~/dev/infra/docker-compose.yml up -d'
alias db-down='docker compose -f ~/dev/infra/docker-compose.yml stop'
alias db-logs='docker compose -f ~/dev/infra/docker-compose.yml logs -f'
```

## 9. Problemas frecuentes

| Síntoma | Causa y solución |
|---|---|
| El contenedor arranca y muere en 2 s | Contraseña de `sa` no cumple la política. Míralo con `docker compose logs sqlserver`. |
| `Login failed for user 'sa'` | La contraseña del cliente no coincide con la del `.env`. Si cambiaste `.env` después de crear el volumen, la contraseña vieja sigue en la base: `docker compose down -v` y vuelve a crear (⚠️ borra datos). |
| `PKIX path building failed` / error de certificado | Falta `TrustServerCertificate=True` (o `-C` en sqlcmd). |
| `Connection refused` | El contenedor no está arriba (`docker compose ps`) o aún está iniciando (espera al healthcheck). |
| El contenedor se mata al iniciar por memoria | SQL Server pide ≥ 2 GB. Cierra cosas o sube la RAM de la VM. |
| Todo lento | Limita la memoria de SQL Server: `MSSQL_MEMORY_LIMIT_MB: 2048` en el `environment`. |

---

## Checklist

- [ ] `docker compose ps` muestra sqlserver como `healthy`
- [ ] `sqlcmd ... -Q "SELECT @@VERSION"` responde
- [ ] Creé la base `Inventario` y una tabla con datos
- [ ] Me conecto desde DBeaver o Azure Data Studio
- [ ] Al menos un lenguaje de mi stack consulta la tabla
- [ ] Hice un backup `.bak` y lo veo en `~/dev/infra/backups/`

---

**Siguiente:** [09 — Uso diario del sistema](09-uso-diario-del-sistema.md)
