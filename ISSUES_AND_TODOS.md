# Rayhunter Project - Issues and Todos

## Open Issues

### 1. Alert Scrollbar Not Displaying in Chrome 🚨

- **Status**: Open
- **Version**: 0.6.2.12
- **Description**: Chrome scrollbar not visible when 5+ alerts are present
- **Attempted Fixes**: 
  - CSS: `overflow-y: scroll`, `scrollbar-gutter: stable`
  - JavaScript: Dynamic overflow control
  - Chrome-specific selectors with `!important`
- **Current State**: Container becomes scrollable but scrollbar remains invisible
- **Impact**: Users cannot see they can scroll through older alerts
- **Browser**: Chrome (specific issue)

## Current Todos

### 1. Fix Alert Scrollbar Visibility in Chrome 🔧
- **Priority**: High
- **Status**: In Progress
- **Description**: Ensure Chrome displays scrollbar when alerts container has overflow content
- **Next Steps**: 
  - Investigate Chrome DevTools for scrollbar rendering
  - Try alternative CSS approaches (e.g., `overflow: scroll` instead of `overflow-y: scroll`)
  - Consider JavaScript-based scrollbar detection and forcing
  - Test with different Chrome versions

### 2. Verify Remove Button Functionality ✅
- **Status**: Completed
- **Description**: Individual alert remove buttons working properly

### 3. Implement HTML Confirmation Modal ✅
- **Status**: Completed  
- **Description**: Replace JavaScript confirm() with custom HTML modal

### 4. Dynamic Container Sizing ✅
- **Status**: Completed
- **Description**: Container grows with alerts up to 4, then becomes scrollable

## Technical Notes

### CSS Properties Tested
- `overflow-y: scroll`
- `scrollbar-gutter: stable`
- `-webkit-overflow-scrolling: touch`
- Chrome-specific selectors with `!important`

### JavaScript Approach
- Dynamic overflow control based on alert count
- Container height calculation: 120px per alert
- Maximum visible alerts: 4 (480px height)
- Overflow handling: `overflow-y: hidden` for ≤4 alerts, `overflow-y: scroll` for 5+ alerts

### Current Workaround
- Container is scrollable but scrollbar invisible
- Users can scroll through content but don't know it's scrollable

## Next Investigation Steps

1. **Chrome DevTools**: Check if scrollbar elements exist but are hidden
2. **Alternative CSS**: Test `overflow: scroll` vs `overflow-y: scroll`
3. **Browser Testing**: Verify if issue exists in other browsers
4. **CSS Reset**: Check if any global CSS is interfering with scrollbar display

## Version History

- **v0.6.2.12**: Current version with scrollbar fixes (scrollbar still not visible)
- **v0.6.2.11**: Added Chrome-specific scrollbar handling
- **v0.6.2.10**: Implemented dynamic container sizing
- **v0.6.2.9**: Fixed scrollbar visibility issues
- **v0.6.2.8**: Added HTML confirmation modal
- **v0.6.2.7**: Fixed remove button functionality
- **v0.6.2.6**: Added confirmation prompts and debugging
- **v0.6.2.5**: Fixed alert rendering and event delegation
- **v0.6.2.4**: Integrated working alert system from debug_alerts.html
- **v0.6.2.3**: Initial alert system implementation

---

*Last Updated: 2025-09-01*
*Current Version: 0.6.2.12*
