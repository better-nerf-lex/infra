# Liquibase Future Migrations

This directory will contain future database migration changesets using Liquibase.

## Current Status

The baseline schema (v1.0) has been deployed via Lambda using `init-schema.sql`. This is marked in `db.changelog-master.xml` as the baseline tag.

## Adding Future Migrations

When you need to make schema changes:

1. Create a new changeset file in `changelogs/`:
   ```bash
   touch changelogs/v1.1-add-new-feature.xml
   ```

2. Define your changes using Liquibase XML format:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <databaseChangeLog
           xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
           xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
           http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.20.xsd">

       <changeSet id="add-user-preferences-table" author="developer">
           <createTable tableName="user_preferences">
               <column name="id" type="UUID">
                   <constraints primaryKey="true"/>
               </column>
               <column name="user_id" type="BIGINT">
                   <constraints nullable="false"/>
               </column>
               <column name="preferences" type="JSONB"/>
           </createTable>
       </changeSet>

   </databaseChangeLog>
   ```

3. Include it in `db.changelog-master.xml`:
   ```xml
   <include file="changelogs/v1.1-add-new-feature.xml"/>
   ```

4. Run Liquibase:
   ```bash
   liquibase --changeLogFile=db.changelog-master.xml update
   ```

## Best Practices

- **One logical change per changeset**: Don't combine unrelated changes
- **Never modify existing changesets**: Once deployed, they're immutable
- **Use descriptive IDs**: `add-user-preferences-table` not `change-1`
- **Add rollback when possible**: Include `<rollback>` tags
- **Test locally first**: Always test migrations in dev before prod

## Documentation

- [Liquibase XML Format](https://docs.liquibase.com/change-types/home.html)
- [Best Practices](https://docs.liquibase.com/concepts/bestpractices.html)
