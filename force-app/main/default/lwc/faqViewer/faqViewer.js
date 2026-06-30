import { LightningElement, track, wire } from 'lwc';
import getFAQs from '@salesforce/apex/FAQController.getFAQs';

const PAGE_SIZE = 10;

export default class FaqViewer extends LightningElement {

    @track searchTerm = '';
    @track faqs = [];
    @track openItems = {};
    @track isLoading = true;
    @track hasError = false;
    @track currentPage = 1;

    _searchTimeout;

    @wire(getFAQs, { searchTerm: '$searchTerm' })
    wiredFAQs({ data, error }) {
        if (data) {
            this.faqs = data;
            this.hasError = false;
            this.currentPage = 1;
        } else if (error) {
            this.hasError = true;
            this.faqs = [];
            console.error('Erro ao carregar FAQs:', error);
        }
        this.isLoading = false;
    }

    get totalPages() {
        return Math.ceil(this.faqs.length / PAGE_SIZE);
    }

    get paginatedFaqs() {
        const start = (this.currentPage - 1) * PAGE_SIZE;
        return this.faqs.slice(start, start + PAGE_SIZE);
    }

    get filteredFaqs() {
        return this.paginatedFaqs.map((faq, index) => {
            const isOpen = !!this.openItems[faq.Id];
            const globalIndex = (this.currentPage - 1) * PAGE_SIZE + index + 1;
            return {
                ...faq,
                isOpen,
                displayIndex: String(globalIndex).padStart(2, '0'),
                answerId: `answer-${faq.Id}`,
                itemClass: `faq-item${isOpen ? ' faq-item--open' : ''}`,
                chevronIcon: isOpen ? 'utility:chevronup' : 'utility:chevrondown'
            };
        });
    }

    get pages() {
        return Array.from({ length: this.totalPages }, (_, i) => ({
            number: i + 1,
            isActive: i + 1 === this.currentPage,
            buttonClass: `page-btn${i + 1 === this.currentPage ? ' page-btn--active' : ''}`
        }));
    }

    get filteredCount() {
        return this.faqs.length;
    }

    get resultLabel() {
        return this.filteredCount === 1 ? 'resultado' : 'resultados';
    }

    get hasResults() {
        return !this.isLoading && !this.hasError && this.filteredFaqs.length > 0;
    }

    get isEmpty() {
        return !this.isLoading && !this.hasError && this.faqs.length === 0;
    }

    get hasPagination() {
        return this.totalPages > 1;
    }

    get isPrevDisabled() {
        return this.currentPage === 1;
    }

    get isNextDisabled() {
        return this.currentPage === this.totalPages;
    }

    handleSearch(event) {
        const value = event.target.value;
        this.isLoading = true;
        clearTimeout(this._searchTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._searchTimeout = setTimeout(() => {
            this.searchTerm = value;
        }, 1000);
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

    goToPage(event) {
        this.currentPage = parseInt(event.currentTarget.dataset.page, 10);
        this.openItems = {};
    }

    prevPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.openItems = {};
        }
    }

    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.openItems = {};
        }
    }
}