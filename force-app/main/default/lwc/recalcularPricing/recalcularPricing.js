import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import executarRecalculo from '@salesforce/apex/PricingService.recalcular';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';

// Importa a referência do campo para não dar erro de digitação
import CAMPO_RECALCULADO from '@salesforce/schema/Order.Precos_Recalculados__c';

export default class RecalcularPricing extends LightningElement {
    @api recordId;

    // "Vigia" o registro do Pedido e traz o valor do checkbox
    @wire(getRecord, { recordId: '$recordId', fields: [CAMPO_RECALCULADO] })
    pedido;

    // Getter para facilitar o uso no HTML
    get precosRecalculados() {
        return getFieldValue(this.pedido.data, CAMPO_RECALCULADO);
    }

    async handleRecalcular() {
        try {
            await executarRecalculo({ orderId: this.recordId });

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