###
Copyright (c) 2014 Ramesh Nair (hiddentao.com)

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
###


squel = undefined
{_, testCreator, assert, expect, should} = require './testbase'
test = testCreator()


test['Postgres flavour'] =
  beforeEach: ->
    delete require.cache[require.resolve('../dist/squel')]
    squel = require "../dist/squel"
    squel = squel.useFlavour 'postgres'

  'INSERT builder':
    beforeEach: -> @inst = squel.insert()

    '>> into(table).set(field, 1).set(field,2).onConflict("field", {field2:2})':
      beforeEach: -> @inst.into('table').set('field', 1).set('field2', 2).onConflict('field', {"field2":2})
      toString: ->
        assert.same @inst.toString(), 'INSERT INTO table (field, field2) VALUES (1, 2) ON CONFLICT (field) DO UPDATE SET field2 = 2'

    '>> into(table).set(field, 1).set(field,2).onConflict("field")':
      beforeEach: -> @inst.into('table').set('field', 1).set('field2', 2).onConflict('field')
      toString: ->
        assert.same @inst.toString(), 'INSERT INTO table (field, field2) VALUES (1, 2) ON CONFLICT (field) DO NOTHING'

    '>> into(table).set(field, 1).set(field,2).onConflict(["field", "field2"], {field3:3})':
      beforeEach: -> @inst.into('table').set('field', 1).set('field2', 2).onConflict(['field', 'field2'], {field3: 3})
      toString: ->
        assert.same @inst.toString(), 'INSERT INTO table (field, field2) VALUES (1, 2) ON CONFLICT (field, field2) DO UPDATE SET field3 = 3'

    '>> into(table).set(field, 1).set(field,2).onConflict(["field", "field2"])':
      beforeEach: -> @inst.into('table').set('field', 1).set('field2', 2).onConflict('field')
      toString: ->
        assert.same @inst.toString(), 'INSERT INTO table (field, field2) VALUES (1, 2) ON CONFLICT (field) DO NOTHING'

    '>> into(table).set(field, 1).set(field,2).onConflict()':
      beforeEach: -> @inst.into('table').set('field', 1).set('field2', 2).onConflict()
      toString: ->
        assert.same @inst.toString(), 'INSERT INTO table (field, field2) VALUES (1, 2) ON CONFLICT DO NOTHING'

    '>> into(table).set(field, 1).returning("*")':
      beforeEach: -> @inst.into('table').set('field', 1).returning('*')
      toString: ->
        assert.same @inst.toString(), 'INSERT INTO table (field) VALUES (1) RETURNING *'

    '>> into(table).set(field, 1).returning("id")':
      beforeEach: -> @inst.into('table').set('field', 1).returning('id')
      toString: ->
        assert.same @inst.toString(), 'INSERT INTO table (field) VALUES (1) RETURNING id'

    '>> into(table).set(field, 1).returning("id").returning("id")':
      beforeEach: -> @inst.into('table').set('field', 1).returning('id').returning('id')
      toString: ->
        assert.same @inst.toString(), 'INSERT INTO table (field) VALUES (1) RETURNING id'

    '>> into(table).set(field, 1).returning("id").returning("name", "alias")':
      beforeEach: -> @inst.into('table').set('field', 1).returning('id').returning('name', 'alias')
      toString: ->
        assert.same @inst.toString(), 'INSERT INTO table (field) VALUES (1) RETURNING id, name AS alias'

    '>> into(table).set(field, 1).returning(squel.str("id < ?", 100), "under100")':
      beforeEach: -> @inst.into('table').set('field', 1).returning(squel.str('id < ?', 100), 'under100')
      toString: ->
        assert.same @inst.toString(), 'INSERT INTO table (field) VALUES (1) RETURNING (id < 100) AS under100'
      toParam: ->
        assert.same @inst.toParam(), {
          "text": 'INSERT INTO table (field) VALUES ($1) RETURNING (id < $2) AS under100',
          "values": [1, 100]
        }


    '>> into(table).set(field, 1).with(alias, table)':
      beforeEach: -> @inst.into('table').set('field', 1).with('alias', squel.select().from('table').where('field = ?', 2))
      toString: ->
        assert.same @inst.toString(), 'WITH alias AS (SELECT * FROM table WHERE (field = 2)) INSERT INTO table (field) VALUES (1)'
      toParam: ->
        assert.same @inst.toParam(), {
          "text": 'WITH alias AS (SELECT * FROM table WHERE (field = $1)) INSERT INTO table (field) VALUES ($2)',
          "values": [2, 1]
        }

  'UPDATE builder':
    beforeEach: -> @upd = squel.update()

    '>> table(table).set(field, 1).returning("*")':
      beforeEach: -> @upd.table('table').set('field', 1).returning('*')
      toString: ->
        assert.same @upd.toString(), 'UPDATE table SET field = 1 RETURNING *'

    '>> table(table).set(field, 1).returning("field")':
      beforeEach: -> @upd.table('table').set('field', 1).returning('field')
      toString: ->
        assert.same @upd.toString(), 'UPDATE table SET field = 1 RETURNING field'

    '>> table(table).set(field, 1).returning("name", "alias")':
      beforeEach: -> @upd.table('table').set('field', 1).returning("name", "alias")
      toString: ->
        assert.same @upd.toString(), 'UPDATE table SET field = 1 RETURNING name AS alias'

    '>> table(table).set(field, 1).from(table2)':
      beforeEach: -> @upd.table('table').set('field', 1).from('table2')
      toString: ->
        assert.same @upd.toString(), 'UPDATE table SET field = 1 FROM table2'

    '>> table(table).set(field, 1).with(alias, table)':
      beforeEach: -> @upd.table('table').set('field', 1).with('alias', squel.select().from('table').where('field = ?', 2))
      toString: ->
        assert.same @upd.toString(), 'WITH alias AS (SELECT * FROM table WHERE (field = 2)) UPDATE table SET field = 1'
      toParam: ->
        assert.same @upd.toParam(), {
          "text": 'WITH alias AS (SELECT * FROM table WHERE (field = $1)) UPDATE table SET field = $2',
          "values": [2, 1]
        }

  'DELETE builder':
    beforeEach: -> @del = squel.delete()

    '>> from(table).where(field = 1).returning("*")':
      beforeEach: -> @del.from('table').where('field = 1').returning('*')
      toString: ->
        assert.same @del.toString(), 'DELETE FROM table WHERE (field = 1) RETURNING *'

    '>> from(table).where(field = 1).returning("field")':
      beforeEach: -> @del.from('table').where('field = 1').returning('field')
      toString: ->
        assert.same @del.toString(), 'DELETE FROM table WHERE (field = 1) RETURNING field'

    '>> from(table).where(field = 1).returning("field", "f")':
      beforeEach: -> @del.from('table').where('field = 1').returning('field', 'f')
      toString: ->
        assert.same @del.toString(), 'DELETE FROM table WHERE (field = 1) RETURNING field AS f'

    '>> from(table).where(field = 1).with(alias, table)':
      beforeEach: -> @del.from('table').where('field = ?', 1).with('alias', squel.select().from('table').where('field = ?', 2))
      toString: ->
        assert.same @del.toString(), 'WITH alias AS (SELECT * FROM table WHERE (field = 2)) DELETE FROM table WHERE (field = 1)'
      toParam: ->
        assert.same @del.toParam(), {
          "text": 'WITH alias AS (SELECT * FROM table WHERE (field = $1)) DELETE FROM table WHERE (field = $2)',
          "values": [2, 1]
        }

  'SELECT builder':
    beforeEach: ->
      @sel = squel.select()
    'select':
      '>> from(table).where(field = 1)':
        beforeEach: ->
          @sel.field('field1').from('table1').where('field1 = 1')
        toString: ->
          assert.same @sel.toString(), 'SELECT field1 FROM table1 WHERE (field1 = 1)'
        toParam: ->
          assert.same @sel.toParam(), {
            "text": 'SELECT field1 FROM table1 WHERE (field1 = 1)'
            "values": []
          }

      '>> from(table).where(field = ?, 2)':
        beforeEach: ->
          @sel.field('field1').from('table1').where('field1 = ?', 2)
        toString: ->
          assert.same @sel.toString(), 'SELECT field1 FROM table1 WHERE (field1 = 2)'
        toParam: ->
          assert.same @sel.toParam(), {
            "text": 'SELECT field1 FROM table1 WHERE (field1 = $1)'
            "values": [2]
          }

    'distinct queries':
      beforeEach: ->
        @sel.fields(['field1', 'field2']).from('table1')

      '>> from(table).distinct()':
        beforeEach: ->
          @sel.distinct()
        toString: ->
          assert.same @sel.toString(), 'SELECT DISTINCT field1, field2 FROM table1'
        toParam: ->
          assert.same @sel.toParam(), {
            'text': 'SELECT DISTINCT field1, field2 FROM table1',
            'values': []
          }

      '>> from(table).distinct(field1)':
        beforeEach: ->
          @sel.distinct('field1')
        toString: ->
          assert.same @sel.toString(), 'SELECT DISTINCT ON (field1) field1, field2 FROM table1'
        toParam: ->
          assert.same @sel.toParam(), {
            'text': 'SELECT DISTINCT ON (field1) field1, field2 FROM table1',
            'values': []
          }

      '>> from(table).distinct(field1, field2)':
        beforeEach: ->
          @sel.distinct('field1', 'field2')
        toString: ->
          assert.same @sel.toString(), 'SELECT DISTINCT ON (field1, field2) field1, field2 FROM table1'
        toParam: ->
          assert.same @sel.toParam(), {
            'text': 'SELECT DISTINCT ON (field1, field2) field1, field2 FROM table1',
            'values': []
          }

    'cte queries':
      beforeEach: ->
        @sel = squel.select()
        @sel2 = squel.select()
        @sel3 = squel.select()

      '>> query1.with(alias, query2)':
        beforeEach: ->
          @sel.from('table1').where('field1 = ?', 1)
          @sel2.from('table2').where('field2 = ?', 2)
          @sel.with('someAlias', @sel2)
        toString: ->
          assert.same @sel.toString(), 'WITH someAlias AS (SELECT * FROM table2 WHERE (field2 = 2)) SELECT * FROM table1 WHERE (field1 = 1)'
        toParam: ->
          assert.same @sel.toParam(), {
            "text": 'WITH someAlias AS (SELECT * FROM table2 WHERE (field2 = $1)) SELECT * FROM table1 WHERE (field1 = $2)'
            "values": [2, 1]
          }

      '>> query1.with(alias1, query2).with(alias2, query2)':
        beforeEach: ->
          @sel.from('table1').where('field1 = ?', 1)
          @sel2.from('table2').where('field2 = ?', 2)
          @sel3.from('table3').where('field3 = ?', 3)
          @sel.with('someAlias', @sel2).with('anotherAlias', @sel3)
        toString: ->
          assert.same @sel.toString(), 'WITH someAlias AS (SELECT * FROM table2 WHERE (field2 = 2)), anotherAlias AS (SELECT * FROM table3 WHERE (field3 = 3)) SELECT * FROM table1 WHERE (field1 = 1)'
        toParam: ->
          assert.same @sel.toParam(), {
            "text": 'WITH someAlias AS (SELECT * FROM table2 WHERE (field2 = $1)), anotherAlias AS (SELECT * FROM table3 WHERE (field3 = $2)) SELECT * FROM table1 WHERE (field1 = $3)'
            "values": [2, 3, 1]
          }


    'union queries':
      beforeEach: ->
        @sel = squel.select()
        @sel2 = squel.select()

      '>> query1.union(query2)':
        beforeEach: ->
          @sel.field('field1').from('table1').where('field1 = ?', 3)
          @sel2.field('field1').from('table1').where('field1 < ?', 10)
          @sel.union(@sel2)
        toString: ->
          assert.same @sel.toString(), 'SELECT field1 FROM table1 WHERE (field1 = 3) UNION (SELECT field1 FROM table1 WHERE (field1 < 10))'
        toParam: ->
          assert.same @sel.toParam(), {
            "text": 'SELECT field1 FROM table1 WHERE (field1 = $1) UNION (SELECT field1 FROM table1 WHERE (field1 < $2))'
            "values": [
              3
              10
            ]
          }

      '>> query1.union_all(query2)':
        beforeEach: ->
          @sel.field('field1').from('table1').where('field1 = ?', 3)
          @sel2.field('field1').from('table1').where('field1 < ?', 10)
          @sel.union_all(@sel2)
        toString: ->
          assert.same @sel.toString(), 'SELECT field1 FROM table1 WHERE (field1 = 3) UNION ALL (SELECT field1 FROM table1 WHERE (field1 < 10))'
        toParam: ->
          assert.same @sel.toParam(), {
            "text": 'SELECT field1 FROM table1 WHERE (field1 = $1) UNION ALL (SELECT field1 FROM table1 WHERE (field1 < $2))'
            "values": [
              3
              10
            ]
          }


  'Default query builder options': ->
    assert.same {
      replaceSingleQuotes: false
      singleQuoteReplacement: '\'\''
      autoQuoteTableNames: false
      autoQuoteFieldNames: false
      autoQuoteAliasNames: false
      useAsForTableAliasNames: true
      nameQuoteCharacter: '`'
      tableAliasQuoteCharacter: '`'
      fieldAliasQuoteCharacter: '"'
      valueHandlers: []
      parameterCharacter: '?'
      numberedParameters: true
      numberedParametersPrefix: '$'
      numberedParametersStartAt: 1
      separator: ' '
      stringFormatter: null
      rawNesting: false
      formatIdentifier: squel.cls.DefaultQueryBuilderOptions.formatIdentifier
    }, squel.cls.DefaultQueryBuilderOptions

  'Identifier sanitization':
    'valid identifiers - lowercase letters, underscores, numbers':
      'simple lowercase identifier':
        beforeEach: -> @result = squel.cls.DefaultQueryBuilderOptions.formatIdentifier('table_name')
        'should not add quotes': -> assert.same @result, 'table_name'

      'identifier with underscore':
        beforeEach: -> @result = squel.cls.DefaultQueryBuilderOptions.formatIdentifier('user_id')
        'should not add quotes': -> assert.same @result, 'user_id'

      'identifier starting with underscore':
        beforeEach: -> @result = squel.cls.DefaultQueryBuilderOptions.formatIdentifier('_private')
        'should not add quotes': -> assert.same @result, '_private'

      'identifier with numbers':
        beforeEach: -> @result = squel.cls.DefaultQueryBuilderOptions.formatIdentifier('table123')
        'should not add quotes': -> assert.same @result, 'table123'

    'invalid identifiers - should be quoted':
      'uppercase letters':
        beforeEach: -> @result = squel.cls.DefaultQueryBuilderOptions.formatIdentifier('TableName')
        'should add quotes': -> assert.same @result, '"TableName"'

      'mixed case':
        beforeEach: -> @result = squel.cls.DefaultQueryBuilderOptions.formatIdentifier('userName')
        'should add quotes': -> assert.same @result, '"userName"'

      'identifier with spaces':
        beforeEach: -> @result = squel.cls.DefaultQueryBuilderOptions.formatIdentifier('user name')
        'should add quotes': -> assert.same @result, '"user name"'

      'identifier with hyphen':
        beforeEach: -> @result = squel.cls.DefaultQueryBuilderOptions.formatIdentifier('user-id')
        'should add quotes': -> assert.same @result, '"user-id"'

      'identifier with special characters':
        beforeEach: -> @result = squel.cls.DefaultQueryBuilderOptions.formatIdentifier('user@domain')
        'should add quotes': -> assert.same @result, '"user@domain"'

      'identifier starting with number':
        beforeEach: -> @result = squel.cls.DefaultQueryBuilderOptions.formatIdentifier('123table')
        'should add quotes': -> assert.same @result, '"123table"'

    'quote escaping':
      'identifier with single double quote':
        beforeEach: -> @result = squel.cls.DefaultQueryBuilderOptions.formatIdentifier('user"name')
        'should escape quotes': -> assert.same @result, '"user""name"'

      'identifier with multiple double quotes':
        beforeEach: -> @result = squel.cls.DefaultQueryBuilderOptions.formatIdentifier('user""name""test')
        'should escape all quotes': -> assert.same @result, '"user""""name""""test"'

      'identifier with quotes and spaces':
        beforeEach: -> @result = squel.cls.DefaultQueryBuilderOptions.formatIdentifier('user "name" test')
        'should escape quotes and add outer quotes': -> assert.same @result, '"user ""name"" test"'

  'Identifier sanitization in queries':
    beforeEach: ->
      @sel = squel.select()
      @ins = squel.insert()
      @upd = squel.update()
      @del = squel.delete()

    'SELECT with uppercase table name':
      beforeEach: -> @sel.from('UserTable').field('id')
      toString: -> assert.same @sel.toString(), 'SELECT id FROM "UserTable"'

    'SELECT with mixed case field name':
      beforeEach: -> @sel.from('users').field('firstName')
      toString: -> assert.same @sel.toString(), 'SELECT "firstName" FROM users'

    'INSERT with special characters in table name':
      beforeEach: -> @ins.into('user-data').set('id', 1)
      toString: -> assert.same @ins.toString(), 'INSERT INTO "user-data" (id) VALUES (1)'

    'UPDATE with spaces in field name':
      beforeEach: -> @upd.table('users').set('full name', 'John Doe')
      toString: -> assert.same @upd.toString(), 'UPDATE users SET "full name" = \'John Doe\''

    'DELETE with quoted identifier':
      beforeEach: -> @del.from('UserData').where('user"id = ?', 1)
      toString: -> assert.same @del.toString(), 'DELETE FROM "UserData" WHERE (user"id = 1)'

    'SELECT with asterisk':
      beforeEach: -> @sel.from('users').field('*')
      toString: -> assert.same @sel.toString(), 'SELECT * FROM users'

    'SELECT with asterisk in the middle':
      beforeEach: -> @sel.from('users').field('user*name')
      toString: -> assert.same @sel.toString(), 'SELECT "user*name" FROM users'


module?.exports[require('path').basename(__filename)] = test
