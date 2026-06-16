<?php
    $term = request()->input('term');
    $image_search = request()->input('image-search');

    if (! is_null($term)) {
        $serachQuery = 'term='.request()->input('term');
    }
?>

<div class="header" id="header">
    <div class="header-top">
        <div class="left-content">
            <ul class="logo-container">
                <li>
                    <a href="{{ route('shop.home.index') }}" aria-label="Logo">
                        @if ($logo = core()->getCurrentChannel()->logo_url)
                            <img class="logo" src="{{ $logo }}" alt="" />
                        @else
                            <img class="logo" src="{{ bagisto_asset('images/logo.svg') }}" alt="" />
                        @endif
                    </a>
                </li>
            </ul>

            <ul class="search-container">
                <li class="search-group">
                    <form role="search" action="{{ route('shop.search.index') }}" method="GET" style="display: inherit;">
                        <label for="search-bar" style="position: absolute; z-index: -1;">Search</label>
                        <input
                            required
                            name="term"
                            type="search"
                            value="{{ ! $image_search ? $term : '' }}"
                            class="search-field"
                            id="search-bar"
                            placeholder="{{ __('shop::app.header.search-text') }}"
                        >

                        <image-search-component></image-search-component>

                        <div class="search-icon-wrapper">
                            <button class="" class="background: none;" aria-label="Search">
                                <i class="icon icon-search"></i>
                            </button>
                        </div>
                    </form>
                </li>
            </ul>
        </div>

        <div class="right-content">
            <span class="search-box"><span class="icon icon-search" id="search"></span></span>

            <ul class="right-content-menu">
                {!! view_render_event('bagisto.shop.layout.header.comppare-item.before') !!}

                @php
                    $showCompare = core()->getConfigData('general.content.shop.compare_option') == "1" ? true : false
                @endphp

                @php
                    $showWishlist = core()->getConfigData('general.content.shop.wishlist_option') == "1" ? true : false;
                @endphp

                {!! view_render_event('bagisto.shop.layout.header.compare-item.after') !!}

                {!! view_render_event('bagisto.shop.layout.header.currency-item.before') !!}

                @if (core()->getCurrentChannel()->currencies->count() > 1)
                    <li class="currency-switcher">
                        <span class="dropdown-toggle">
                            {{ core()->getCurrentCurrencyCode() }}
                            <i class="icon arrow-down-icon"></i>
                        </span>

                        <ul class="dropdown-list currency">
                            @foreach (core()->getCurrentChannel()->currencies as $currency)
                                <li>
                                    @if (isset($serachQuery))
                                        <a href="?{{ $serachQuery }}&currency={{ $currency->code }}">{{ $currency->code }}</a>
                                    @else
                                        <a href="?currency={{ $currency->code }}">{{ $currency->code }}</a>
                                    @endif
                                </li>
                            @endforeach
                        </ul>
                    </li>
                @endif

                {!! view_render_event('bagisto.shop.layout.header.currency-item.after') !!}

                {!! view_render_event('bagisto.shop.layout.header.account-item.before') !!}

                <li>
                    <span class="dropdown-toggle">
                        <i class="icon account-icon"></i>
                        <span class="name">{{ __('shop::app.header.account') }}</span>
                        <i class="icon arrow-down-icon"></i>
                    </span>

                    @guest('customer')
                        <ul class="dropdown-list account guest">
                            <li>
                                <div>
                                    <label style="color: #9e9e9e; font-weight: 700; text-transform: uppercase; font-size: 15px;">
                                        {{ __('shop::app.header.title') }}
                                    </label>
                                </div>

                                <div style="margin-top: 5px;">
                                    <span style="font-size: 12px;">{{ __('shop::app.header.dropdown-text') }}</span>
                                </div>

                                <div class="button-group">
                                    <a class="btn btn-primary btn-md" href="{{ route('customer.session.index') }}" style="color: #ffffff">
                                        {{ __('shop::app.header.sign-in') }}
                                    </a>

                                    <a class="btn btn-primary btn-md" href="{{ route('customer.register.index') }}" style="float: right; color: #ffffff">
                                        {{ __('shop::app.header.sign-up') }}
                                    </a>
                                </div>
                            </li>
                        </ul>
                    @endguest

                    @auth('customer')
                        @php
                           $showWishlist = core()->getConfigData('general.content.shop.wishlist_option') == "1" ? true : false;
                        @endphp

                        <ul class="dropdown-list account customer">
                            <li>
                                <div>
                                    <label style="color: #9e9e9e; font-weight: 700; text-transform: uppercase; font-size: 15px;">
                                        {{ auth()->guard('customer')->user()->first_name }}
                                    </label>
                                </div>

                                <ul>
                                    <li>
                                        <a href="{{ route('customer.profile.index') }}">{{ __('shop::app.header.profile') }}</a>
                                    </li>

                                    @if ($showWishlist)
                                        <li>
                                            <a href="{{ route('customer.wishlist.index') }}">{{ __('shop::app.header.wishlist') }}</a>
                                        </li>
                                    @endif

                                    @if ($showCompare)                                    
                                    <li>
                                        <a
                                            @auth('customer')
                                                href="{{ route('velocity.customer.product.compare') }}"
                                            @endauth

                                            @guest('customer')
                                                href="{{ route('velocity.product.compare') }}"
                                            @endguest
                                            
                                        > {{ __('shop::app.customer.compare.text') }}
                                        </a>
                                    </li>
                                    @endif

                                    <li>
                                        <form id="customerLogout" action="{{ route('customer.session.destroy') }}" method="POST">
                                            @csrf
                                            @method('DELETE')
                                        </form>

                                        <a
                                            href="{{ route('customer.session.destroy') }}"
                                            onclick="event.preventDefault(); document.getElementById('customerLogout').submit();">
                                            {{ __('shop::app.header.logout') }}
                                        </a>
                                    </li>
                                </ul>
                            </li>
                        </ul>
                    @endauth
                </li>

                {!! view_render_event('bagisto.shop.layout.header.account-item.after') !!}

                {!! view_render_event('bagisto.shop.layout.header.cart-item.before') !!}

                <li class="cart-dropdown-container">
                    @include('shop::checkout.cart.mini-cart')
                </li>

                {!! view_render_event('bagisto.shop.layout.header.cart-item.after') !!}
            </ul>

            <span class="menu-box" ><span class="icon icon-menu" id="hammenu"></span>
        </div>
    </div>

    <div class="header-bottom" id="header-bottom">
        @include('shop::layouts.header.nav-menu.navmenu')
    </div>

    <div class="search-responsive mt-10" id="search-responsive">
        <form role="search" action="{{ route('shop.search.index') }}" method="GET" style="display: inherit;">
            <div class="search-content">
                <button style="background: none; border: none; padding: 0px;">
                    <i class="icon icon-search"></i>
                </button>

                <image-search-component></image-search-component>

                <input type="search" name="term" class="search">
                <i class="icon icon-menu-back right"></i>
            </div>
        </form>
    </div>
</div>

<category-products-popup></category-products-popup>

@push('scripts')
    <script src="https://cdn.jsdelivr.net/npm/@tensorflow/tfjs" defer></script>
    <script src="https://cdn.jsdelivr.net/npm/@tensorflow-models/mobilenet" defer></script>

    <script type="text/x-template" id="category-products-popup-template">
        <div v-if="isOpen" style="position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.6); z-index: 9999; display: flex; align-items: center; justify-content: center; padding: 20px;">
            <div style="background: #ffffff; width: 100%; max-width: 750px; border-radius: 12px; padding: 25px; box-shadow: 0 10px 25px rgba(0,0,0,0.2); position: relative; max-height: 85vh; overflow-y: auto;">
                
                <button @click="closeModal" style="position: absolute; top: 15px; right: 20px; background: none; border: none; font-size: 28px; cursor: pointer; color: #64748b; line-height: 1;">&times;</button>
                
                <div style="margin-bottom: 20px; border-bottom: 1px solid #e2e8f0; padding-bottom: 10px;">
                    <h3 style="font-size: 20px; font-weight: 700; color: #1e293b;">Koleksi @{{ categoryName }}</h3>
                </div>

                <div v-if="isLoading" style="text-align: center; padding: 40px 0;">
                    <p style="color: #64748b; font-size: 14px;">Sedang memuat produk terbaru...</p>
                </div>

                <div v-else-if="products.length > 0" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 16px;">
                    <div v-for="product in products" :key="product.id" style="border: 1px solid #e2e8f0; padding: 12px; border-radius: 8px; text-align: center; background: #fafafa; display: flex; flex-direction: column; justify-content: space-between;">
                        <div>
                            <img :src="product.base_image.small_image_url" :alt="product.name" style="width: 100%; height: 130px; object-fit: cover; border-radius: 6px; margin-bottom: 8px;">
                            <h4 style="font-size: 13px; font-weight: 600; color: #334155; margin: 4px 0; text-overflow: ellipsis; white-space: nowrap; overflow: hidden;" :title="product.name">@{{ product.name }}</h4>
                        </div>
                        <div>
                            <p style="font-size: 14px; color: #db2777; font-weight: 700; margin-top: 4px;">@{{ product.formated_price }}</p>
                            <a :href="'/products/' + product.url_key" style="display: block; margin-top: 8px; background: #000000; color: #ffffff; text-decoration: none; font-size: 11px; padding: 6px 12px; border-radius: 4px; font-weight: 500;">Lihat Detail</a>
                        </div>
                    </div>
                </div>

                <div v-else style="text-align: center; padding: 40px 0; color: #94a3b8;">
                    Belum ada produk aktif yang tersedia di kategori ini.
                </div>
            </div>
        </div>
    </script>

    <script type="text/x-template" id="image-search-component-template">
        <div v-if="image_search_status">
            <label class="image-search-container" :for="'image-search-container-' + _uid">
                <i class="icon camera-icon"></i>
                <input type="file" :id="'image-search-container-' + _uid" ref="image_search_input" v-on:change="uploadImage()"/>
                <img :id="'uploaded-image-url-' +  + _uid" :src="uploaded_image_url" alt="" width="20" height="20" style="display:none" />
            </label>
        </div>
    </script>

    <script>
        // Registrasi Global Komponen Modal Kategori Kecantikan
        Vue.component('category-products-popup', {
            template: '#category-products-popup-template',
            data: function() {
                return {
                    isOpen: false,
                    isLoading: false,
                    categoryName: '',
                    products: []
                }
            },
            mounted: function() {
                var self = this;
                // Menangkap event kiriman dari navmenu.blade.php
                self.$root.$on('open-category-popup', function(category) {
                    var localeName = category.name;
                    if (category.translations && category.translations.length) {
                        category.translations.forEach(function(trans) {
                            if (trans.locale == document.documentElement.lang) {
                                localeName = trans.name;
                            }
                        });
                    }
                    self.categoryName = localeName;
                    self.isOpen = true;
                    self.loadProducts(category.id);
                });
            },
            methods: {
                loadProducts: function(categoryId) {
                    var self = this;
                    self.isLoading = true;
                    self.products = [];

                    axios.get('/api/v1/products', {
                        params: { category_id: categoryId }
                    })
                    .then(function(response) {
                        self.products = response.data.data;
                        self.isLoading = false;
                    })
                    .catch(function(error) {
                        console.error("Gagal mengambil produk API:", error);
                        self.isLoading = false;
                    });
                },
                closeModal: function() {
                    this.isOpen = false;
                    this.products = [];
                }
            }
        });

        Vue.component('image-search-component', {
            template: '#image-search-component-template',
            data: function() {
                return {
                    uploaded_image_url: '',
                    image_search_status: "{{core()->getConfigData('general.content.shop.image_search') == '1' ? 'true' : 'false'}}" == 'true'
                }
            },
            methods: {
                uploadImage: function() {
                    var imageInput = this.$refs.image_search_input;

                    if (imageInput.files && imageInput.files[0]) {
                        if (imageInput.files[0].type.includes('image/')) {
                            var self = this;

                            if (imageInput.files[0].size <= 2000000) {
                                self.$root.showLoader();

                                var formData = new FormData();
                                formData.append('image', imageInput.files[0]);

                                axios.post("{{ route('shop.image.search.upload') }}", formData, {headers: {'Content-Type': 'multipart/form-data'}})
                                    .then(function(response) {
                                        self.uploaded_image_url = response.data;
                                        var net;

                                        async function app() {
                                            var analysedResult = [];
                                            var queryString = '';

                                            net = await mobilenet.load();
                                            const imgElement = document.getElementById('uploaded-image-url-' +  + self._uid);

                                            try {
                                                const result = await net.classify(imgElement);

                                                result.forEach(function(value) {
                                                    queryString = value.className.split(',');

                                                    if (queryString.length > 1) {
                                                        analysedResult = analysedResult.concat(queryString)
                                                    } else {
                                                        analysedResult.push(queryString[0])
                                                    }
                                                });
                                            } catch (error) {
                                                self.$root.hideLoader();
                                                window.flashMessages = [{'type': 'alert-error', 'message': "{{ __('shop::app.common.error') }}"}];
                                                self.$root.addFlashMessages();
                                            };

                                            localStorage.searched_image_url = self.uploaded_image_url;
                                            queryString = localStorage.searched_terms = analysedResult.join('_');
                                            self.$root.hideLoader();

                                            window.location.href = "{{ route('shop.search.index') }}" + '?term=' + queryString + '&image-search=1';
                                        }

                                        app();
                                    })
                                    .catch(function(error) {
                                        self.$root.hideLoader();
                                        window.flashMessages = [{'type': 'alert-error', 'message': "{{ __('shop::app.common.error') }}"}];
                                        self.$root.addFlashMessages();
                                    });
                            } else {
                                imageInput.value = '';
                                window.flashMessages = [{'type': 'alert-error', 'message': "{{ __('shop::app.common.image-upload-limit') }}"}];
                                self.$root.addFlashMessages();
                            }
                        } else {
                            imageInput.value = '';
                            alert('Only images (.jpeg, .jpg, .png, ..) are allowed.');
                        }
                    }
                }
            }
        });
    </script>

    <script>
        $(document).ready(function() {
            $('body').delegate('#search, .icon-menu-close, .icon.icon-menu', 'click', function(e) {
                toggleDropdown(e);
            });

            @auth('customer')
                @php
                    $compareCount = app('Webkul\Velocity\Repositories\VelocityCustomerCompareProductRepository')
                        ->count([
                            'customer_id' => auth()->guard('customer')->user()->id,
                        ]);
                @endphp

                let comparedItems = JSON.parse(localStorage.getItem('compared_product'));
                $('#compare-items-count').html({{ $compareCount }});
            @endauth

            @guest('customer')
                let comparedItems = JSON.parse(localStorage.getItem('compared_product'));
                $('#compare-items-count').html(comparedItems ? comparedItems.length : 0);
            @endguest

            function toggleDropdown(e) {
                var currentElement = $(e.currentTarget);

                if (currentElement.hasClass('icon-search')) {
                    currentElement.removeClass('icon-search');
                    currentElement.addClass('icon-menu-close');
                    $('#hammenu').removeClass('icon-menu-close');
                    $('#hammenu').addClass('icon-menu');
                    $("#search-responsive").css("display", "block");
                    $("#header-bottom").css("display", "none");
                } else if (currentElement.hasClass('icon-menu')) {
                    currentElement.removeClass('icon-menu');
                    currentElement.addClass('icon-menu-close');
                    $('#search').removeClass('icon-menu-close');
                    $('#search').addClass('icon-search');
                    $("#search-responsive").css("display", "none");
                    $("#header-bottom").css("display", "block");
                } else {
                    currentElement.removeClass('icon-menu-close');
                    $("#search-responsive").css("display", "none");
                    $("#header-bottom").css("display", "none");
                    if (currentElement.attr("id") == 'search') {
                        currentElement.addClass('icon-search');
                    } else {
                        currentElement.addClass('icon-menu');
                    }
                }
            }
        });
    </script>
@endpush