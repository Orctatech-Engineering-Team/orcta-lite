#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODULES_DIR="$PROJECT_ROOT/src/modules"
APP_FILE="$PROJECT_ROOT/src/app.ts"
REQUESTS_DIR="$PROJECT_ROOT/requests"

# Usage
usage() {
    echo -e "${BLUE}Usage:${NC} pnpm new:module <name> [--with-repo] [--no-register]"
    echo ""
    echo "Arguments:"
    echo "  name          Module name in kebab-case (e.g., blog-posts)"
    echo ""
    echo "Options:"
    echo "  --with-repo   Include a repository file for data access"
    echo "  --no-register Skip auto-registration in app.ts"
    echo ""
    echo "Examples:"
    echo "  pnpm new:module posts"
    echo "  pnpm new:module user-profiles --with-repo"
    exit 1
}

# Validate module name (kebab-case)
validate_name() {
    if [[ ! $1 =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; then
        echo -e "${RED}Error:${NC} Module name must be kebab-case (e.g., blog-posts)"
        exit 1
    fi
}

# Convert kebab-case to PascalCase
to_pascal_case() {
    echo "$1" | sed -r 's/(^|-)([a-z])/\U\2/g'
}

# Convert kebab-case to camelCase
to_camel_case() {
    local pascal=$(to_pascal_case "$1")
    echo "${pascal,}"
}

# Register module in app.ts
register_module() {
    local module_name="$1"
    local camel_name="$2"

    if [[ ! -f "$APP_FILE" ]]; then
        echo -e "  ${YELLOW}⚠${NC} app.ts not found, skipping registration"
        return
    fi

    # Check if already registered
    if grep -q "from \"@/modules/${module_name}\"" "$APP_FILE"; then
        echo -e "  ${YELLOW}⚠${NC} Module already registered in app.ts"
        return
    fi

    # Find the last module import line and add after it
    local last_import_line=$(grep -n "from \"@/modules/" "$APP_FILE" | tail -1 | cut -d: -f1)

    if [[ -n "$last_import_line" ]]; then
        # Add import after last module import
        sed -i "${last_import_line}a import ${camel_name} from \"@/modules/${module_name}\";" "$APP_FILE"
        echo -e "  ${GREEN}✓${NC} Added import to app.ts"
    else
        # No module imports found, add after hono imports
        local hono_import_line=$(grep -n "from \"hono" "$APP_FILE" | tail -1 | cut -d: -f1)
        if [[ -n "$hono_import_line" ]]; then
            sed -i "${hono_import_line}a\\
\\
import ${camel_name} from \"@/modules/${module_name}\";" "$APP_FILE"
            echo -e "  ${GREEN}✓${NC} Added import to app.ts"
        fi
    fi

    # Find the last app.route line and add after it
    local last_route_line=$(grep -n "app.route(" "$APP_FILE" | tail -1 | cut -d: -f1)

    if [[ -n "$last_route_line" ]]; then
        sed -i "${last_route_line}a app.route(\"/\", ${camel_name});" "$APP_FILE"
        echo -e "  ${GREEN}✓${NC} Added route to app.ts"
    fi
}

# Main
if [[ $# -lt 1 ]]; then
    usage
fi

MODULE_NAME="$1"
WITH_REPO=false
NO_REGISTER=false

# Parse flags
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-repo)
            WITH_REPO=true
            shift
            ;;
        --no-register)
            NO_REGISTER=true
            shift
            ;;
        *)
            echo -e "${RED}Error:${NC} Unknown option $1"
            usage
            ;;
    esac
done

validate_name "$MODULE_NAME"

PASCAL_NAME=$(to_pascal_case "$MODULE_NAME")
CAMEL_NAME=$(to_camel_case "$MODULE_NAME")
MODULE_DIR="$MODULES_DIR/$MODULE_NAME"

# Check if module already exists
if [[ -d "$MODULE_DIR" ]]; then
    echo -e "${RED}Error:${NC} Module '$MODULE_NAME' already exists at $MODULE_DIR"
    exit 1
fi

echo -e "${BLUE}Creating module:${NC} $MODULE_NAME"

# Create module directory
mkdir -p "$MODULE_DIR"

# Generate index.ts (routes + handlers)
cat > "$MODULE_DIR/index.ts" << EOF
import { Hono } from "hono";
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";
import { jsonSuccess, jsonError, HttpStatus } from "@/lib/response";

const ${CAMEL_NAME} = new Hono();

// Schemas
const create${PASCAL_NAME}Schema = z.object({
	name: z.string().min(1),
});

const ${CAMEL_NAME}ParamsSchema = z.object({
	id: z.string().uuid(),
});

// Routes

/**
 * GET /${MODULE_NAME}
 * List all ${MODULE_NAME}
 */
${CAMEL_NAME}.get("/${MODULE_NAME}", async (c) => {
	// TODO: implement
	return jsonSuccess(c, []);
});

/**
 * GET /${MODULE_NAME}/:id
 * Get a single ${MODULE_NAME} by ID
 */
${CAMEL_NAME}.get(
	"/${MODULE_NAME}/:id",
	zValidator("param", ${CAMEL_NAME}ParamsSchema),
	async (c) => {
		const { id } = c.req.valid("param");
		// TODO: implement
		return jsonError(c, "NOT_FOUND", "${PASCAL_NAME} not found", HttpStatus.NOT_FOUND);
	}
);

/**
 * POST /${MODULE_NAME}
 * Create a new ${MODULE_NAME}
 */
${CAMEL_NAME}.post(
	"/${MODULE_NAME}",
	zValidator("json", create${PASCAL_NAME}Schema),
	async (c) => {
		const input = c.req.valid("json");
		// TODO: implement
		return jsonSuccess(c, { id: crypto.randomUUID(), ...input }, HttpStatus.CREATED);
	}
);

/**
 * DELETE /${MODULE_NAME}/:id
 * Delete a ${MODULE_NAME}
 */
${CAMEL_NAME}.delete(
	"/${MODULE_NAME}/:id",
	zValidator("param", ${CAMEL_NAME}ParamsSchema),
	async (c) => {
		const { id } = c.req.valid("param");
		// TODO: implement
		return c.body(null, HttpStatus.NO_CONTENT);
	}
);

export default ${CAMEL_NAME};
EOF

echo -e "  ${GREEN}✓${NC} Created index.ts"

# Generate test file
cat > "$MODULE_DIR/${MODULE_NAME}.test.ts" << EOF
import { describe, it, expect } from "vitest";
import app from "@/app";

describe("${PASCAL_NAME}", () => {
	describe("GET /${MODULE_NAME}", () => {
		it("returns empty list", async () => {
			const res = await app.request("/${MODULE_NAME}");
			expect(res.status).toBe(200);

			const body = await res.json();
			expect(body).toEqual({
				success: true,
				data: [],
			});
		});
	});

	describe("POST /${MODULE_NAME}", () => {
		it("creates a new ${MODULE_NAME}", async () => {
			const res = await app.request("/${MODULE_NAME}", {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({ name: "Test" }),
			});
			expect(res.status).toBe(201);

			const body = await res.json();
			expect(body.success).toBe(true);
			expect(body.data.name).toBe("Test");
			expect(body.data.id).toBeDefined();
		});

		it("validates input", async () => {
			const res = await app.request("/${MODULE_NAME}", {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({}),
			});
			expect(res.status).toBe(400);
		});
	});
});
EOF

echo -e "  ${GREEN}✓${NC} Created ${MODULE_NAME}.test.ts"

# Generate .http file for API testing
cat > "$REQUESTS_DIR/${MODULE_NAME}.http" << EOF
### List ${PASCAL_NAME}

GET {{base}}/${MODULE_NAME}

### Get ${PASCAL_NAME} by ID

GET {{base}}/${MODULE_NAME}/{{id}}

### Create ${PASCAL_NAME}

POST {{base}}/${MODULE_NAME}
Content-Type: {{contentType}}

{
  "name": "Test ${PASCAL_NAME}"
}

### Delete ${PASCAL_NAME}

DELETE {{base}}/${MODULE_NAME}/{{id}}
EOF

echo -e "  ${GREEN}✓${NC} Created requests/${MODULE_NAME}.http"

# Generate repository file if requested
if [[ "$WITH_REPO" == true ]]; then
cat > "$MODULE_DIR/${MODULE_NAME}.repository.ts" << EOF
import { eq } from "drizzle-orm";
import { db } from "@/db";
import { tryInfra } from "@/lib/infra";
import { ok, err, type Result } from "@/lib/result";
import type { InfrastructureError } from "@/lib/infra";

// TODO: Import your schema
// import { ${CAMEL_NAME} } from "@/db";

type NotFound = { type: "NOT_FOUND" };
type ${PASCAL_NAME}Error = NotFound | InfrastructureError;

export async function findAll() {
	return tryInfra(async () => {
		// TODO: implement
		// return db.query.${CAMEL_NAME}.findMany();
		return [];
	});
}

export async function findById(id: string): Promise<Result<unknown, ${PASCAL_NAME}Error>> {
	const result = await tryInfra(async () => {
		// TODO: implement
		// return db.query.${CAMEL_NAME}.findFirst({ where: eq(${CAMEL_NAME}.id, id) });
		return null;
	});

	if (!result.ok) return result;
	if (!result.value) return err({ type: "NOT_FOUND" });

	return ok(result.value);
}

export async function create(data: { name: string }) {
	return tryInfra(async () => {
		// TODO: implement
		// const [record] = await db.insert(${CAMEL_NAME}).values(data).returning();
		// return record;
		return { id: crypto.randomUUID(), ...data };
	});
}

export async function remove(id: string) {
	return tryInfra(async () => {
		// TODO: implement
		// await db.delete(${CAMEL_NAME}).where(eq(${CAMEL_NAME}.id, id));
	});
}
EOF

echo -e "  ${GREEN}✓${NC} Created ${MODULE_NAME}.repository.ts"
fi

# Auto-register in app.ts
if [[ "$NO_REGISTER" == false ]]; then
    register_module "$MODULE_NAME" "$CAMEL_NAME"
fi

# Done
echo ""
echo -e "${GREEN}Module created successfully!${NC}"
echo ""

if [[ "$NO_REGISTER" == true ]]; then
    echo -e "${BLUE}Next steps:${NC}"
    echo ""
    echo "1. Register the module in src/app.ts:"
    echo ""
    echo -e "   ${GREEN}import ${CAMEL_NAME} from \"@/modules/${MODULE_NAME}\";${NC}"
    echo -e "   ${GREEN}app.route(\"/\", ${CAMEL_NAME});${NC}"
    echo ""
fi

if [[ "$WITH_REPO" == true ]]; then
    echo "Add your database schema to src/db/schema.ts"
    echo "Then update the repository with your schema imports"
    echo ""
fi

echo -e "Run tests:  ${GREEN}pnpm test${NC}"
echo -e "Test API:   ${GREEN}pnpm http ${MODULE_NAME}${NC}"
