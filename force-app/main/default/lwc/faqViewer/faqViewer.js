import { LightningElement, track, wire } from 'lwc';
import getFAQs from '@salesforce/apex/FAQController.getFAQs';

const PAGE_SIZE = 10;

export default class FaqViewer extends LightningElement {

    @track searchTerm = '';
    @track currentPage = 1;
    @track faqs = [];
    @track totalRecords = 0;
    @track isLoading = false;
    @track hasError = false;

    _searchTimeout;

    @wire(getFAQs, { searchTerm: '$searchTerm', pageNumber: '$currentPage' })
    wiredFAQs({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.faqs = data.records;
            this.totalRecords = data.totalRecords;
            this.hasError = false;
        } else if (error) {
            this.hasError = true;
            this.faqs = [];
            console.error('Erro ao carregar FAQs:', error);
        }
    }

    get totalPages() {
        return Math.ceil(this.totalRecords / PAGE_SIZE);
    }

    get filteredFaqs() {
        return this.faqs.map((faq) => ({
            ...faq,
            answerId: `answer-${faq.Id}`
        }));
    }

    get pages() {
        const maxButtons = 5; // Mostrar max 5 botões
        let startPage = Math.max(1, this.currentPage - 2);
        let endPage = Math.min(this.totalPages, startPage + maxButtons - 1);
        startPage = Math.max(1, endPage - maxButtons + 1);

        return Array.from({ length: endPage - startPage + 1 }, (_, i) => ({
            number: startPage + i,
            buttonClass: `page-btn${startPage + i === this.currentPage ? ' page-btn--active' : ''}`
        }));
    }

    get resultLabel() {
        return this.totalRecords === 1 ? 'resultado' : 'resultados';
    }

    get hasResults() {
        return !this.isLoading && !this.hasError && this.faqs.length > 0;
    }

    get isEmpty() {
        return !this.isLoading && !this.hasError && this.totalRecords === 0;
    }

    get hasPagination() {
        return this.totalPages > 1;
    }

    handleSearch(event) {
        const value = event.target.value;
        this.isLoading = true;
        clearTimeout(this._searchTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._searchTimeout = setTimeout(() => {
            this.searchTerm = value;
            this.currentPage = 1; // Volta pra página 1 ao buscar
        }, 1000);
    }

    clearSearch() {
        this.searchTerm = '';
        this.currentPage = 1;
        this.template.querySelector('.faq-search__input').value = '';
    }

    goToPage(event) {
        this.currentPage = parseInt(event.currentTarget.dataset.page, 10);
        // Scroll pra top
        this.template.querySelector('.faq-content').scrollTop = 0;
    }
}