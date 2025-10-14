/**
 * MediaBox AI V2 - Responsive & TV Navigation Script
 * Handles dynamic scaling, keyboard navigation, and TV remote support
 */

(function() {
  'use strict';

  // ========================================
  // 1. DYNAMIC SCALING
  // ========================================
  
  function getScalingFactor() {
    const width = window.screen.width;
    
    if (width >= 7680) return 4.0;      // 8K
    if (width >= 3840) return 2.0;      // 4K
    if (width >= 1920) return 1.5;      // Full HD
    if (width >= 1280) return 1.25;     // Standard TV
    if (width >= 768) return 1.0;       // Tablet
    return 0.875;                        // Mobile
  }

  function applyScaling() {
    const scale = getScalingFactor();
    document.documentElement.style.setProperty('--scale', scale);
  }

  // Apply scaling on load
  applyScaling();

  // Re-apply scaling on resize (debounced)
  let resizeTimer;
  window.addEventListener('resize', () => {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(() => {
      applyScaling();
    }, 250);
  });

  // ========================================
  // 2. TV REMOTE NAVIGATION
  // ========================================
  
  class TVNavigator {
    constructor() {
      this.currentFocus = 0;
      this.focusableElements = [];
      this.gridElements = [];
      this.isTVMode = false;
      this.init();
    }

    init() {
      this.detectTVMode();
      this.updateFocusableElements();
      this.setupKeyboardNavigation();
      this.setupGridNavigation();
      
      // Re-detect focusable elements when DOM changes
      const observer = new MutationObserver(() => {
        this.updateFocusableElements();
      });
      observer.observe(document.body, { childList: true, subtree: true });
    }

    detectTVMode() {
      // Detect if running on a TV or large display
      const isLargeScreen = window.screen.width >= 1920;
      const hasRemote = navigator.getGamepads ? navigator.getGamepads().length > 0 : false;
      
      this.isTVMode = isLargeScreen || hasRemote;
      
      if (this.isTVMode) {
        document.body.classList.add('tv-mode');
        console.log('TV Mode enabled');
      }
    }

    updateFocusableElements() {
      this.focusableElements = Array.from(document.querySelectorAll(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      ));
      
      this.gridElements = Array.from(document.querySelectorAll('.service-card'));
    }

    setupKeyboardNavigation() {
      document.addEventListener('keydown', (e) => {
        if (!this.isTVMode && !e.ctrlKey && !e.metaKey) {
          return; // Only handle in TV mode or with modifiers
        }

        switch(e.key) {
          case 'ArrowUp':
            this.navigateUp(e);
            break;
          case 'ArrowDown':
            this.navigateDown(e);
            break;
          case 'ArrowLeft':
            this.navigateLeft(e);
            break;
          case 'ArrowRight':
            this.navigateRight(e);
            break;
          case 'Enter':
          case ' ':
            this.activateElement(e);
            break;
          case 'Escape':
            this.goBack(e);
            break;
        }
      });
    }

    navigateUp(e) {
      e.preventDefault();
      this.currentFocus = Math.max(0, this.currentFocus - 1);
      this.focusableElements[this.currentFocus]?.focus();
    }

    navigateDown(e) {
      e.preventDefault();
      this.currentFocus = Math.min(this.focusableElements.length - 1, this.currentFocus + 1);
      this.focusableElements[this.currentFocus]?.focus();
    }

    navigateLeft(e) {
      e.preventDefault();
      this.navigateGrid('left');
    }

    navigateRight(e) {
      e.preventDefault();
      this.navigateGrid('right');
    }

    activateElement(e) {
      e.preventDefault();
      const activeElement = document.activeElement;
      if (activeElement && (activeElement.tagName === 'BUTTON' || activeElement.tagName === 'A')) {
        activeElement.click();
      }
    }

    goBack(e) {
      e.preventDefault();
      // Close modals, go back, etc.
      const modals = document.querySelectorAll('.modal.active');
      if (modals.length > 0) {
        modals[modals.length - 1].classList.remove('active');
      } else {
        history.back();
      }
    }

    setupGridNavigation() {
      // Grid navigation for service cards
      this.gridElements.forEach((card, index) => {
        card.addEventListener('focus', () => {
          this.currentGridIndex = index;
        });
      });
    }

    navigateGrid(direction) {
      const currentIndex = this.currentGridIndex || 0;
      const columns = this.getGridColumns();
      let newIndex;

      if (direction === 'left') {
        newIndex = Math.max(0, currentIndex - 1);
      } else if (direction === 'right') {
        newIndex = Math.min(this.gridElements.length - 1, currentIndex + 1);
      }

      if (this.gridElements[newIndex]) {
        this.gridElements[newIndex].focus();
        this.currentGridIndex = newIndex;
      }
    }

    getGridColumns() {
      const width = window.innerWidth;
      if (width >= 7680) return 6;      // 8K
      if (width >= 3840) return 5;      // 4K
      if (width >= 1920) return 4;      // Full HD
      if (width >= 1280) return 3;      // Standard TV
      if (width >= 768) return 2;       // Tablet
      return 1;                         // Mobile
    }
  }

  // Initialize TV Navigator
  const tvNavigator = new TVNavigator();

  // ========================================
  // 3. TOUCH GESTURE SUPPORT
  // ========================================
  
  class TouchGestures {
    constructor() {
      this.touchStartX = 0;
      this.touchStartY = 0;
      this.touchEndX = 0;
      this.touchEndY = 0;
      this.swipeThreshold = 50;
      this.init();
    }

    init() {
      document.addEventListener('touchstart', (e) => {
        this.touchStartX = e.changedTouches[0].screenX;
        this.touchStartY = e.changedTouches[0].screenY;
      }, { passive: true });

      document.addEventListener('touchend', (e) => {
        this.touchEndX = e.changedTouches[0].screenX;
        this.touchEndY = e.changedTouches[0].screenY;
        this.handleSwipe();
      }, { passive: true });
    }

    handleSwipe() {
      const deltaX = this.touchEndX - this.touchStartX;
      const deltaY = this.touchEndY - this.touchStartY;

      // Horizontal swipe
      if (Math.abs(deltaX) > Math.abs(deltaY)) {
        if (Math.abs(deltaX) > this.swipeThreshold) {
          if (deltaX > 0) {
            this.onSwipeRight();
          } else {
            this.onSwipeLeft();
          }
        }
      }
      // Vertical swipe
      else {
        if (Math.abs(deltaY) > this.swipeThreshold) {
          if (deltaY > 0) {
            this.onSwipeDown();
          } else {
            this.onSwipeUp();
          }
        }
      }
    }

    onSwipeLeft() {
      tvNavigator.navigateRight(new KeyboardEvent('keydown', { key: 'ArrowRight' }));
    }

    onSwipeRight() {
      tvNavigator.navigateLeft(new KeyboardEvent('keydown', { key: 'ArrowLeft' }));
    }

    onSwipeUp() {
      tvNavigator.navigateUp(new KeyboardEvent('keydown', { key: 'ArrowUp' }));
    }

    onSwipeDown() {
      tvNavigator.navigateDown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
    }
  }

  // Initialize touch gestures
  const touchGestures = new TouchGestures();

  // ========================================
  // 4. PERFORMANCE OPTIMIZATION
  // ========================================
  
  // Debounce function
  function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  }

  // Throttle function
  function throttle(func, limit) {
    let inThrottle;
    return function() {
      const args = arguments;
      const context = this;
      if (!inThrottle) {
        func.apply(context, args);
        inThrottle = true;
        setTimeout(() => inThrottle = false, limit);
      }
    };
  }

  // Lazy load images
  function lazyLoadImages() {
    const images = document.querySelectorAll('img[data-src]');
    
    const imageObserver = new IntersectionObserver((entries, observer) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const img = entry.target;
          img.src = img.dataset.src;
          img.removeAttribute('data-src');
          observer.unobserve(img);
        }
      });
    });

    images.forEach(img => imageObserver.observe(img));
  }

  // Initialize lazy loading
  if ('IntersectionObserver' in window) {
    lazyLoadImages();
  }

  // ========================================
  // 5. RESPONSIVE UTILITIES
  // ========================================
  
  window.ResponsiveUtils = {
    // Get current breakpoint
    getBreakpoint() {
      const width = window.innerWidth;
      if (width >= 7680) return '8k';
      if (width >= 3840) return '4k';
      if (width >= 1920) return 'full-hd';
      if (width === 1600) return 'projector';  // Projector specific
      if (width >= 1280) return 'hd';
      if (width === 1143) return 'taboneplus';  // TabOnePlus specific
      if (width >= 768) return 'tablet';
      return 'mobile';
    },

    // Check if mobile
    isMobile() {
      return window.innerWidth < 768;
    },

    // Check if tablet
    isTablet() {
      return window.innerWidth >= 768 && window.innerWidth < 1280;
    },

    // Check if TV
    isTV() {
      return window.innerWidth >= 1280;
    },

    // Check if 4K or higher
    is4K() {
      return window.innerWidth >= 3840;
    },

    // Get scaling factor
    getScalingFactor() {
      return getScalingFactor();
    },

    // Check if TabOnePlus
    isTabOnePlus() {
      return window.innerWidth === 1143;
    },

    // Focus first focusable element
    focusFirst() {
      const firstElement = document.querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
      if (firstElement) {
        firstElement.focus();
      }
    }
  };

  // ========================================
  // 6. ACCESSIBILITY ENHANCEMENTS
  // ========================================
  
  // Announce to screen readers
  function announceToScreenReader(message) {
    const announcement = document.createElement('div');
    announcement.setAttribute('role', 'status');
    announcement.setAttribute('aria-live', 'polite');
    announcement.setAttribute('aria-atomic', 'true');
    announcement.className = 'sr-only';
    announcement.textContent = message;
    
    document.body.appendChild(announcement);
    
    setTimeout(() => {
      document.body.removeChild(announcement);
    }, 1000);
  }

  // Skip to main content
  function createSkipLink() {
    const skipLink = document.createElement('a');
    skipLink.href = '#main-content';
    skipLink.textContent = 'Skip to main content';
    skipLink.className = 'skip-link';
    skipLink.style.cssText = `
      position: absolute;
      top: -40px;
      left: 0;
      background: #000;
      color: #fff;
      padding: 8px;
      text-decoration: none;
      z-index: 1000;
    `;
    
    skipLink.addEventListener('focus', () => {
      skipLink.style.top = '0';
    });
    
    skipLink.addEventListener('blur', () => {
      skipLink.style.top = '-40px';
    });
    
    document.body.insertBefore(skipLink, document.body.firstChild);
  }

  // Initialize accessibility features
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', createSkipLink);
  } else {
    createSkipLink();
  }

  // ========================================
  // 7. CONSOLE LOG
  // ========================================
  
  console.log('MediaBox AI V2 - Responsive System Loaded');
  console.log('Breakpoint:', window.ResponsiveUtils.getBreakpoint());
  console.log('Scaling Factor:', window.ResponsiveUtils.getScalingFactor());
  console.log('TV Mode:', tvNavigator.isTVMode);

})();

