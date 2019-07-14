
local T = require 'tests.lib.simple-test'

print('---  Running Unit Tests  ---')

T.check(require('tests.unit.test_transform'))

print('---  Finished Unit Tests  ---')

T.plan()
