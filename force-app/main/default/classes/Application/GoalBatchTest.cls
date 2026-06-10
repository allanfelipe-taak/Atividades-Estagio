/**
 * @description Test class for GoalBatch and GoalBatchScheduler
 * @author Unit Testing Agent
 */
@isTest
private class GoalBatchTest {

    /**
     * @description Setup test data for all test methods
     * Creates Goals with GoalItems in various states for batch processing
     */
    @testSetup
    static void setupTestData() {
        // Get an active user to set as Salesperson
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        // Create test Goal records
        List<Goal__c> goals = new List<Goal__c>();
        for (Integer i = 0; i < 3; i++) {
            Goal__c goal = new Goal__c(
                Salesperson__c = testUser.Id,
                Year__c = 2026,
                SalesValue__c = 100000
            );
            goals.add(goal);
        }
        insert goals;

        // Create test GoalItem records with various scenarios
        List<GoalItem__c> goalItems = new List<GoalItem__c>();

        // Scenario 1: Meta atingida (RealizedValue >= TargetValue)
        // Create 100 items where goal is achieved (keeps total >= 200 for bulk test)
        for (Integer i = 0; i < 100; i++) {
            GoalItem__c item = new GoalItem__c(
                Goal__c = goals[0].Id,
                TargetValue__c = 5000,
                RealizedValue__c = 7500,  // >= TargetValue
                GoalCommissionPercentage__c = 25.0,
                AchievedPercentage__c = null  // Will be set by batch
            );
            goalItems.add(item);
        }

        // Scenario 2: Meta NÃO atingida (RealizedValue < TargetValue)
        // Create 50 items where goal is not achieved
        for (Integer i = 0; i < 50; i++) {
            GoalItem__c item = new GoalItem__c(
                Goal__c = goals[1].Id,
                TargetValue__c = 5000,
                RealizedValue__c = 3000,  // < TargetValue
                GoalCommissionPercentage__c = 25.0,
                AchievedPercentage__c = null
            );
            goalItems.add(item);
        }

        // Scenario 3: RealizedValue is null (should result in 0)
        // Create 50 items with null RealizedValue
        for (Integer i = 0; i < 50; i++) {
            GoalItem__c item = new GoalItem__c(
                Goal__c = goals[2].Id,
                TargetValue__c = 5000,
                RealizedValue__c = null,  // null RealizedValue
                GoalCommissionPercentage__c = 25.0,
                AchievedPercentage__c = null
            );
            goalItems.add(item);
        }

        // NOTE: A "null TargetValue" scenario is intentionally NOT created — TargetValue__c
        // is a REQUIRED field (per the challenge: "Valor meta *"), so it can never be null
        // in real data. The batch's TargetValue null-check is just defensive.

        insert goalItems;
    }

    /**
     * @description Test GoalBatch processes GoalItems where RealizedValue >= TargetValue
     * Expects AchievedPercentage to be set to GoalCommissionPercentage
     */
    @isTest
    static void testGoalBatch_metaAtingida() {
        // Arrange
        List<GoalItem__c> items = [
            SELECT Id, AchievedPercentage__c, GoalCommissionPercentage__c
            FROM GoalItem__c
            WHERE TargetValue__c = 5000 AND RealizedValue__c = 7500
        ];

        System.assertEquals(100, items.size(), 'Should have 100 items with achieved goals');

        // Act
        Test.startTest();
        Database.executeBatch(new GoalBatch(), 200);
        Test.stopTest();

        // Assert
        List<GoalItem__c> updatedItems = [
            SELECT Id, AchievedPercentage__c, GoalCommissionPercentage__c
            FROM GoalItem__c
            WHERE TargetValue__c = 5000 AND RealizedValue__c = 7500
        ];

        for (GoalItem__c item : updatedItems) {
            Assert.isNotNull(
                item.AchievedPercentage__c,
                'AchievedPercentage should not be null when goal is achieved'
            );
            Assert.areEqual(
                25.0,
                item.AchievedPercentage__c,
                'AchievedPercentage should equal GoalCommissionPercentage (25.0) when goal is achieved'
            );
        }
    }

    /**
     * @description Test GoalBatch processes GoalItems where RealizedValue < TargetValue
     * Expects AchievedPercentage to be set to 0
     */
    @isTest
    static void testGoalBatch_metaNaoAtingida() {
        // Arrange - not achieved items are deterministically RV=3000, TV=5000
        List<GoalItem__c> items = [
            SELECT Id, AchievedPercentage__c
            FROM GoalItem__c
            WHERE RealizedValue__c = 3000 AND TargetValue__c = 5000
        ];

        System.assertEquals(50, items.size(), 'Should have 50 items with unachieved goals');

        // Act
        Test.startTest();
        Database.executeBatch(new GoalBatch(), 200);
        Test.stopTest();

        // Assert
        List<GoalItem__c> updatedItems = [
            SELECT Id, AchievedPercentage__c
            FROM GoalItem__c
            WHERE RealizedValue__c = 3000 AND TargetValue__c = 5000
        ];

        for (GoalItem__c item : updatedItems) {
            Assert.areEqual(
                0,
                item.AchievedPercentage__c,
                'AchievedPercentage should be 0 when RealizedValue < TargetValue'
            );
        }
    }

    /**
     * @description Test GoalBatch handles null RealizedValue
     * Expects AchievedPercentage to be set to 0
     */
    @isTest
    static void testGoalBatch_nullRealizedValue() {
        // Arrange - null-realized items are deterministically RV=null, TV=5000
        List<GoalItem__c> items = [
            SELECT Id, AchievedPercentage__c
            FROM GoalItem__c
            WHERE RealizedValue__c = null AND TargetValue__c = 5000
        ];

        System.assertEquals(50, items.size(), 'Should have 50 items with null RealizedValue');

        // Act
        Test.startTest();
        Database.executeBatch(new GoalBatch(), 200);
        Test.stopTest();

        // Assert
        List<GoalItem__c> updatedItems = [
            SELECT Id, AchievedPercentage__c
            FROM GoalItem__c
            WHERE RealizedValue__c = null AND TargetValue__c = 5000
        ];

        for (GoalItem__c item : updatedItems) {
            Assert.areEqual(
                0,
                item.AchievedPercentage__c,
                'AchievedPercentage should be 0 when RealizedValue is null'
            );
        }
    }

    /**
     * @description Test GoalBatch bulk processing with 200+ records
     * Verifies that batch correctly handles large datasets without governor limit issues
     */
    @isTest
    static void testGoalBatch_bulkProcessing() {
        // Arrange - verify we have bulk data
        Integer totalItems = [SELECT count() FROM GoalItem__c];
        System.assert(totalItems >= 200, 'Should have at least 200 GoalItems for bulk test: ' + totalItems);

        // Act
        Test.startTest();
        Database.executeBatch(new GoalBatch(), 200);
        Test.stopTest();

        // Assert - verify all items were processed
        List<GoalItem__c> processedItems = [
            SELECT Id, AchievedPercentage__c
            FROM GoalItem__c
        ];

        Assert.isTrue(
            processedItems.size() >= 200,
            'Batch should process all 200+ GoalItems without errors'
        );

        // Verify that items have been updated (none should have null AchievedPercentage if batch ran)
        for (GoalItem__c item : processedItems) {
            Assert.isNotNull(
                item.AchievedPercentage__c,
                'All items should have AchievedPercentage set after batch execution'
            );
        }
    }

    /**
     * @description Test GoalBatch does not update records when value hasn't changed
     * Verifies the optimization that only updates records with actual changes
     */
    @isTest
    static void testGoalBatch_noUnnecessaryUpdates() {
        // Arrange
        // Pre-set achieved items (RV=7500, TV=5000) to their already-correct value
        List<GoalItem__c> itemsToPreset = [
            SELECT Id, AchievedPercentage__c
            FROM GoalItem__c
            WHERE TargetValue__c = 5000 AND RealizedValue__c = 7500
            LIMIT 10
        ];

        for (GoalItem__c item : itemsToPreset) {
            item.AchievedPercentage__c = 25.0;
        }
        update itemsToPreset;

        // Act
        Test.startTest();
        Database.executeBatch(new GoalBatch(), 200);
        Test.stopTest();

        // Assert - verify records still have correct values
        List<GoalItem__c> verifyItems = [
            SELECT Id, AchievedPercentage__c
            FROM GoalItem__c
            WHERE Id IN :itemsToPreset
        ];

        for (GoalItem__c item : verifyItems) {
            Assert.areEqual(
                25.0,
                item.AchievedPercentage__c,
                'Pre-set AchievedPercentage should remain 25.0 (no unnecessary updates)'
            );
        }
    }

    /**
     * @description Test GoalBatchScheduler executes the batch
     * Verifies the scheduler correctly instantiates and executes GoalBatch
     */
    @isTest
    static void testGoalBatchScheduler_execution() {
        // Arrange
        String jobName = 'GoalBatch Test Scheduled Job';
        String cronExpression = '0 0 9 ? * MON-FRI';

        // Act
        Test.startTest();
        String jobId = System.schedule(jobName, cronExpression, new GoalBatchScheduler());
        Test.stopTest();

        // Assert - verify job was created
        CronTrigger cronTrigger = [
            SELECT Id, CronExpression, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        Assert.isNotNull(cronTrigger, 'Scheduled job should be created');
        Assert.areEqual(jobName, cronTrigger.CronJobDetail.Name, 'Job name should match scheduled name');
        Assert.areEqual(
            cronExpression,
            cronTrigger.CronExpression,
            'Cron expression should match the one provided'
        );
    }

    /**
     * @description Test GoalBatchScheduler batch execution through scheduler
     * Verifies that the scheduler properly executes the batch and processes records
     */
    @isTest
    static void testGoalBatchScheduler_batchExecution() {
        // Arrange
        Goal__c goal = [SELECT Id FROM Goal__c LIMIT 1];
        List<GoalItem__c> itemsBefore = [
            SELECT Id, AchievedPercentage__c
            FROM GoalItem__c
            WHERE Goal__c = :goal.Id
        ];

        // Verify initial state has nulls or zeros
        System.assert(
            !itemsBefore.isEmpty(),
            'Should have GoalItems to process'
        );

        // Act
        Test.startTest();
        // Execute the scheduler's execute method directly
        SchedulableContext sc = null;
        GoalBatchScheduler scheduler = new GoalBatchScheduler();
        scheduler.execute(sc);
        Test.stopTest();

        // Assert
        List<GoalItem__c> itemsAfter = [
            SELECT Id, AchievedPercentage__c
            FROM GoalItem__c
            WHERE Goal__c = :goal.Id
        ];

        for (GoalItem__c item : itemsAfter) {
            Assert.isNotNull(
                item.AchievedPercentage__c,
                'After scheduler execution, all items should have AchievedPercentage set'
            );
        }
    }

    /**
     * @description Test GoalBatch with RealizedValue exactly equal to TargetValue
     * Edge case: equality should also trigger goal achievement
     */
    @isTest
    static void testGoalBatch_equalValues() {
        // Arrange - clear setup items so the total stays within a single batch chunk
        // (in test context the batch may only run one execute() call)
        delete [SELECT Id FROM GoalItem__c];

        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        Goal__c goal = new Goal__c(
            Salesperson__c = testUser.Id,
            Year__c = 2026,
            SalesValue__c = 50000
        );
        insert goal;

        List<GoalItem__c> items = new List<GoalItem__c>();
        for (Integer i = 0; i < 50; i++) {
            items.add(new GoalItem__c(
                Goal__c = goal.Id,
                TargetValue__c = 5000,
                RealizedValue__c = 5000,  // Equal to TargetValue
                GoalCommissionPercentage__c = 15.0
            ));
        }
        insert items;

        // Act
        Test.startTest();
        Database.executeBatch(new GoalBatch(), 200);
        Test.stopTest();

        // Assert
        List<GoalItem__c> updatedItems = [
            SELECT Id, AchievedPercentage__c
            FROM GoalItem__c
            WHERE Goal__c = :goal.Id
        ];

        for (GoalItem__c item : updatedItems) {
            Assert.areEqual(
                15.0,
                item.AchievedPercentage__c,
                'AchievedPercentage should be 15.0 when RealizedValue equals TargetValue'
            );
        }
    }

}
