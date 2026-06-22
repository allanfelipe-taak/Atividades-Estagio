import { LightningElement, track, wire } from 'lwc';
import getFAQs from '@salesforce/apex/FAQController.getFAQs';

export default class FaqViewer extends LightningElement {

    @track searchTerm = '';
    @track faqs = [];
    @track openItems = {};
    @track isLoading = true;
    @track hasError = false;

    _searchTimeout;

    @wire(getFAQs, { searchTerm: '$searchTerm' })
    wiredFAQs({ data, error }) {
        if (data) {
            this.faqs = data;
            this.hasError = false;
        } else if (error) {
            this.hasError = true;
            this.faqs = [];
            console.error('Erro ao carregar FAQs:', error);
        }
        this.isLoading = false;
    }

    get filteredFaqs() {
        return this.faqs.map((faq, index) => {
            const isOpen = !!this.openItems[faq.Id];
            return {
                ...faq,
                isOpen,
                displayIndex: String(index + 1).padStart(2, '0'),
                answerId: `answer-${faq.Id}`,
                itemClass: `faq-item${isOpen ? ' faq-item--open' : ''}`,
                chevronIcon: isOpen ? 'utility:chevronup' : 'utility:chevrondown'
            };
        });
    }

    get filteredCount() {
        return this.filteredFaqs.length;
    }

    get resultLabel() {
        return this.filteredCount === 1 ? 'resultado' : 'resultados';
    }

    get pluralSuffix() {
        return '';
    }

    get hasResults() {
        return !this.isLoading && !this.hasError && this.filteredFaqs.length > 0;
    }

    get isEmpty() {
        return !this.isLoading && !this.hasError && this.filteredFaqs.length === 0;
    }

    handleSearch(event) {
        const value = event.target.value;
        this.isLoading = true;

        clearTimeout(this._searchTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._searchTimeout = setTimeout(() => {
            this.searchTerm = value;
        }, 300);
    }

    clearSearch() {
        this.searchTerm = '';
        this.template.querySelector('.faq-search__input').value = '';
    }

    toggleItem(event) {
        const id = event.currentTarget.dataset.id;
        const isCurrentlyOpen = !!this.openItems[id];

        this.openItems = {};
        if (!isCurrentlyOpen) {
            this.openItems = { [id]: true };
        }
    }
}