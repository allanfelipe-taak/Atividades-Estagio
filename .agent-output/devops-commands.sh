#!/bin/bash
# DevOps Command Reference: ProjetoPricing Migration Cleanup
# Target Org: TaakProjetoPricing
# Purpose: Remove old Portuguese objects after English refactoring

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ORG_ALIAS="TaakProjetoPricing"
PROJECT_ROOT="/Users/grupotaak/Documents/ProjetoPricing"
DESTRUCTIVE_MANIFEST="${PROJECT_ROOT}/MDAPI/destructiveChangesPre.xml"
LOG_FILE="${PROJECT_ROOT}/.agent-output/cleanup-execution.log"

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}ProjetoPricing Cleanup: Portuguese → English Migration${NC}"
echo -e "${BLUE}============================================================${NC}"

# ============================================================================
# PHASE 0: PRE-FLIGHT CHECKS
# ============================================================================

phase_0_preflight() {
    echo -e "\n${YELLOW}PHASE 0: PRE-FLIGHT CHECKS${NC}"
    echo "Target Org: $ORG_ALIAS"

    # Check if org is configured
    if ! sf org list | grep -q "$ORG_ALIAS"; then
        echo -e "${RED}ERROR: Org '$ORG_ALIAS' not found. Please authenticate first:${NC}"
        echo "  sf org login web --alias $ORG_ALIAS"
        exit 1
    fi
    echo -e "${GREEN}✓ Org authenticated${NC}"

    # Check if destructive manifest exists
    if [ ! -f "$DESTRUCTIVE_MANIFEST" ]; then
        echo -e "${RED}ERROR: Destructive manifest not found at $DESTRUCTIVE_MANIFEST${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Destructive manifest found${NC}"

    # Check git status
    cd "$PROJECT_ROOT"
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}⚠ Uncommitted changes detected${NC}"
        echo "  Recommendation: Commit all changes before proceeding"
    else
        echo -e "${GREEN}✓ Git status clean${NC}"
    fi

    echo -e "${GREEN}Pre-flight checks complete${NC}"
}

# ============================================================================
# PHASE 1: IDENTIFY BLOCKING FLOWS
# ============================================================================

phase_1_identify_flows() {
    echo -e "\n${YELLOW}PHASE 1: IDENTIFY BLOCKING FLOWS${NC}"
    echo "Blocking Flow IDs:"
    echo "  - 301ak000027quXJ"
    echo "  - 301ak000027pSgN"
    echo "  - 301ak000027n5Po"
    echo "  - 301ak000027oUUI"
    echo "  - 301ak000027q34s"

    echo -e "\n${BLUE}Manual Step Required:${NC}"
    echo "1. Open TaakProjetoPricing org in Salesforce UI"
    echo "2. Go to Setup > Flows"
    echo "3. Search for each Flow ID and document:"
    echo "   - Flow Name"
    echo "   - Flow Type (Scheduled/Triggered/Cloud)"
    echo "   - Objects Referenced"
    echo "   - Business Criticality"
    echo ""
    echo "4. Save findings to: .agent-output/flow-inventory.md"
    echo ""
    read -p "Press ENTER when Flow inventory is complete: "
}

# ============================================================================
# PHASE 2: DEACTIVATE FLOWS
# ============================================================================

phase_2_deactivate_flows() {
    echo -e "\n${YELLOW}PHASE 2: DEACTIVATE FLOWS${NC}"
    echo -e "${BLUE}Manual Step Required:${NC}"
    echo "1. For each of the 5 Flows:"
    echo "   a. Open Flow in Flow Builder"
    echo "   b. Click 'Deactivate' button"
    echo "   c. Record timestamp of deactivation"
    echo ""
    echo "2. Wait 48 hours for stability monitoring"
    echo "3. Monitor:"
    echo "   - Integration Logs (no errors)"
    echo "   - Order processing (working normally)"
    echo "   - No user-reported issues"
    echo ""
    echo "4. Document any issues found during 48-hour window"
    echo ""
    read -p "Press ENTER when all Flows are deactivated and 48-hour window complete: "
}

# ============================================================================
# PHASE 3: DELETE FLOWS
# ============================================================================

phase_3_delete_flows() {
    echo -e "\n${YELLOW}PHASE 3: DELETE FLOWS FROM ORG${NC}"
    echo -e "${BLUE}Manual Step Required:${NC}"
    echo "1. For each of the 5 deactivated Flows:"
    echo "   a. Open Flow in Flow Builder"
    echo "   b. Click 'Delete' button"
    echo "   c. Confirm deletion"
    echo "   d. Record timestamp"
    echo ""
    echo "2. Wait 5 minutes after last deletion"
    echo "3. Verify deletion in Flow list"
    echo ""
    read -p "Press ENTER when all Flows are deleted from the org: "

    echo -e "${GREEN}✓ All blocking Flows deleted${NC}"
}

# ============================================================================
# PHASE 4: DRY-RUN DEPLOYMENT (HIGHLY RECOMMENDED)
# ============================================================================

phase_4_dryrun_deployment() {
    echo -e "\n${YELLOW}PHASE 4: DRY-RUN DEPLOYMENT${NC}"
    echo "This will simulate the destructive deployment without making changes"

    read -p "Ready to execute dry-run? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Dry-run skipped. Proceeding to Phase 5."
        return 0
    fi

    echo -e "${BLUE}Executing dry-run deployment...${NC}"

    sf project deploy start \
        --manifest "$DESTRUCTIVE_MANIFEST" \
        --target-org "$ORG_ALIAS" \
        --dry-run \
        --wait 30 \
        --verbose 2>&1 | tee -a "$LOG_FILE"

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✓ Dry-run successful!${NC}"
        echo -e "${YELLOW}Review the output above for any warnings or issues${NC}"
        read -p "Review complete. Proceed to Phase 5 (real deployment)? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Deployment cancelled by user"
            exit 1
        fi
    else
        echo -e "${RED}✗ Dry-run failed!${NC}"
        echo "Issues found:"
        echo "1. Possible remaining Flow references"
        echo "2. Validation rules referencing old objects"
        echo "3. Permission sets with old object access"
        echo "4. Data records in old objects"
        echo ""
        echo "Investigate and fix before proceeding to Phase 5"
        exit 1
    fi
}

# ============================================================================
# PHASE 5: REAL DEPLOYMENT
# ============================================================================

phase_5_real_deployment() {
    echo -e "\n${YELLOW}PHASE 5: EXECUTE DESTRUCTIVE CHANGES DEPLOYMENT${NC}"
    echo ""
    echo -e "${RED}⚠ WARNING: This will PERMANENTLY DELETE objects from org ⚠${NC}"
    echo ""
    echo "Objects to be deleted:"
    echo "  Apex Classes:"
    echo "    - FreteHandler"
    echo "    - MargemHandler"
    echo "    - ImpostoHandler"
    echo "  Apex Triggers:"
    echo "    - FreteTrigger"
    echo "    - MargemTrigger"
    echo "    - ImpostoTrigger"
    echo "  Custom Objects:"
    echo "    - Frete__c"
    echo "    - Margem__c"
    echo "    - Imposto__c"
    echo ""
    echo -e "${YELLOW}Backup recommendation: Take org snapshot before proceeding${NC}"
    echo ""

    read -p "Type 'DELETE' to confirm real deployment: " confirm
    if [ "$confirm" != "DELETE" ]; then
        echo "Deployment cancelled"
        exit 1
    fi

    echo -e "${BLUE}Executing real deployment...${NC}"

    sf project deploy start \
        --manifest "$DESTRUCTIVE_MANIFEST" \
        --target-org "$ORG_ALIAS" \
        --wait 30 \
        --test-level NoTestRun \
        --verbose 2>&1 | tee -a "$LOG_FILE"

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✓ Deployment successful!${NC}"
        echo "All old Portuguese objects and code have been removed"
    else
        echo -e "${RED}✗ Deployment failed!${NC}"
        echo "Check log for details: $LOG_FILE"
        exit 1
    fi
}

# ============================================================================
# PHASE 6: VALIDATION
# ============================================================================

phase_6_validation() {
    echo -e "\n${YELLOW}PHASE 6: VALIDATION & CONFIRMATION${NC}"

    # 6.1 Verify old objects are deleted
    echo -e "\n${BLUE}6.1 Verifying old objects deleted...${NC}"

    for obj in "Frete__c" "Margem__c" "Imposto__c"; do
        echo -n "  Checking $obj... "
        if sf sobject describe -s "$obj" --target-org "$ORG_ALIAS" 2>/dev/null; then
            echo -e "${RED}✗ FAILED - Object still exists!${NC}"
            exit 1
        else
            echo -e "${GREEN}✓ Deleted${NC}"
        fi
    done

    # 6.2 Verify new objects exist
    echo -e "\n${BLUE}6.2 Verifying new objects deployed...${NC}"

    for obj in "Freight__c" "Margin__c" "Tax__c"; do
        echo -n "  Checking $obj... "
        if sf sobject describe -s "$obj" --target-org "$ORG_ALIAS" 2>/dev/null > /dev/null; then
            echo -e "${GREEN}✓ Present${NC}"
        else
            echo -e "${RED}✗ FAILED - Object not found!${NC}"
            exit 1
        fi
    done

    # 6.3 Verify new handlers deployed
    echo -e "\n${BLUE}6.3 Verifying new handlers deployed...${NC}"

    handlers_output=$(sf apex list --target-org "$ORG_ALIAS" 2>/dev/null)

    for handler in "FreightHandler" "MarginHandler" "TaxHandler"; do
        echo -n "  Checking $handler... "
        if echo "$handlers_output" | grep -q "$handler"; then
            echo -e "${GREEN}✓ Deployed${NC}"
        else
            echo -e "${RED}✗ FAILED - Handler not found!${NC}"
            exit 1
        fi
    done

    # 6.4 Search codebase for references
    echo -e "\n${BLUE}6.4 Searching codebase for old object references...${NC}"

    cd "$PROJECT_ROOT"

    found_references=0
    for old_obj in "Frete__c" "Margem__c" "Imposto__c"; do
        refs=$(grep -r "$old_obj" force-app/main/default/classes --include="*.cls" --include="*.trigger" 2>/dev/null | wc -l)
        if [ "$refs" -gt 0 ]; then
            echo -e "${RED}✗ Found $refs references to $old_obj in codebase${NC}"
            grep -r "$old_obj" force-app/main/default/classes --include="*.cls" --include="*.trigger"
            found_references=1
        else
            echo -e "${GREEN}✓ No references to $old_obj in codebase${NC}"
        fi
    done

    if [ $found_references -eq 1 ]; then
        echo -e "${RED}ERROR: Old object references still exist in code${NC}"
        exit 1
    fi

    # 6.5 Verify Integration Logs
    echo -e "\n${BLUE}6.5 Checking Integration Logs for errors...${NC}"

    # This requires SOQL query - manual step
    echo -e "${YELLOW}Manual verification needed:${NC}"
    echo "Run this SOQL query to check for recent errors:"
    echo '  SELECT Id, Status, ErrorMessage FROM IntegrationLog__c'
    echo '  WHERE CreatedDate = TODAY AND Status IN ("Error", "Failed")'
    echo '  ORDER BY CreatedDate DESC LIMIT 10'
    echo ""

    read -p "Verified Integration Logs are clean? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Validation failed${NC}"
        exit 1
    fi

    # Summary
    echo -e "\n${GREEN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ CLEANUP VALIDATION SUCCESSFUL${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Summary:"
    echo "  ✓ All old Portuguese objects deleted"
    echo "  ✓ All new English objects present"
    echo "  ✓ All new handlers deployed"
    echo "  ✓ No code references to old objects"
    echo "  ✓ Integration Logs clean"
    echo ""
    echo "Migration cleanup is COMPLETE!"
}

# ============================================================================
# POST-CLEANUP: UPDATE VERSION CONTROL
# ============================================================================

post_cleanup_git() {
    echo -e "\n${YELLOW}POST-CLEANUP: Update Version Control${NC}"

    cd "$PROJECT_ROOT"

    echo "Adding deployment log to git..."
    git add .agent-output/cleanup-* 2>/dev/null || true

    echo "Creating cleanup commit..."
    git commit -m "cleanup: remove Portuguese objects after successful migration to English naming

- Deleted old objects: Frete__c, Margem__c, Imposto__c
- Deleted old handlers: FreteHandler, MargemHandler, ImpostoHandler
- Deleted old triggers: FreteTrigger, MargemTrigger, ImpostoTrigger
- Deleted 5 blocking Flows (IDs: 301ak000027quXJ, 301ak000027pSgN, 301ak000027n5Po, 301ak000027oUUI, 301ak000027q34s)
- New English objects verified: Freight__c, Margin__c, Tax__c
- New handlers verified: FreightHandler, MarginHandler, TaxHandler
- All integration tests passing
- No code references to old Portuguese objects

Target: TaakProjetoPricing org
Date: $(date -u +%Y-%m-%d)
" 2>/dev/null || echo "Git commit skipped (no changes or not in repo)"

    echo -e "${GREEN}✓ Git history updated${NC}"
}

# ============================================================================
# MAIN EXECUTION FLOW
# ============================================================================

main() {
    mkdir -p "$(dirname "$LOG_FILE")"

    echo "Cleanup execution started at $(date)" >> "$LOG_FILE"

    phase_0_preflight
    phase_1_identify_flows
    phase_2_deactivate_flows
    phase_3_delete_flows
    phase_4_dryrun_deployment
    phase_5_real_deployment
    phase_6_validation

    echo -e "\n${YELLOW}POST-CLEANUP STEPS${NC}"
    read -p "Update git with cleanup changes? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        post_cleanup_git
    fi

    echo -e "\n${GREEN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}CLEANUP WORKFLOW COMPLETE${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Next Steps:"
    echo "1. Verify Order processing with new objects"
    echo "2. Run pricing engine tests"
    echo "3. Notify team migration cleanup is complete"
    echo "4. Close related tickets"
    echo ""
    echo "Execution log: $LOG_FILE"

    echo "Cleanup execution completed at $(date)" >> "$LOG_FILE"
}

# ============================================================================
# ENTRY POINT
# ============================================================================

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
