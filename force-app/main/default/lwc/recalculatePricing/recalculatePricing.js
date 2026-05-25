import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import executeRecalculation from '@salesforce/apex/PricingService.recalculate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';

// Importa a referência do campo para não dar erro de digitação
import FIELD_PRICES_RECALCULATED from '@salesforce/schema/Order.PricesRecalculated__c';

export default class RecalculatePricing extends LightningElement {
    @api recordId;

    // "Vigia" o registro do Pedido e traz o valor do checkbox
    @wire(getRecord, { recordId: '$recordId', fields: [FIELD_PRICES_RECALCULATED] })
    order;

    // Getter para facilitar o uso no HTML
    get pricesRecalculated() {
        return getFieldValue(this.order.data, FIELD_PRICES_RECALCULATED);
    }

    async handleRecalculate() {
        try {
            await executeRecalculation({ orderId: this.recordId });

            this.dispatchEvent(new ShowToastEvent({
                title: 'Sucesso',
                message: 'Preços atualizados!',
                variant: 'success'
            }));

            // Atualiza a tela e o @wire percebe a mudança sozinho!
            this.dispatchEvent(new RefreshEvent());

        } catch (error) {
            console.error('Erro ao recalcular:', error);
        }
    }
}