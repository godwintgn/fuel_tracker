---
name: FuelTrack Pro
colors:
  surface: '#fbf9f9'
  surface-dim: '#dbdad9'
  surface-bright: '#fbf9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3f3'
  surface-container: '#efeded'
  surface-container-high: '#e9e8e7'
  surface-container-highest: '#e3e2e2'
  on-surface: '#1b1c1c'
  on-surface-variant: '#40493d'
  inverse-surface: '#303031'
  inverse-on-surface: '#f2f0f0'
  outline: '#707a6c'
  outline-variant: '#bfcaba'
  surface-tint: '#1b6d24'
  primary: '#0d631b'
  on-primary: '#ffffff'
  primary-container: '#2e7d32'
  on-primary-container: '#cbffc2'
  inverse-primary: '#88d982'
  secondary: '#005faf'
  on-secondary: '#ffffff'
  secondary-container: '#54a0fe'
  on-secondary-container: '#003567'
  tertiary: '#884200'
  on-tertiary: '#ffffff'
  tertiary-container: '#ad5600'
  on-tertiary-container: '#ffeee6'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#a3f69c'
  primary-fixed-dim: '#88d982'
  on-primary-fixed: '#002204'
  on-primary-fixed-variant: '#005312'
  secondary-fixed: '#d4e3ff'
  secondary-fixed-dim: '#a5c8ff'
  on-secondary-fixed: '#001c3a'
  on-secondary-fixed-variant: '#004786'
  tertiary-fixed: '#ffdcc6'
  tertiary-fixed-dim: '#ffb786'
  on-tertiary-fixed: '#311300'
  on-tertiary-fixed-variant: '#723600'
  background: '#fbf9f9'
  on-background: '#1b1c1c'
  surface-variant: '#e3e2e2'
typography:
  display-lg:
    fontFamily: Roboto Flex
    fontSize: 57px
    fontWeight: '400'
    lineHeight: 64px
    letterSpacing: -0.25px
  headline-lg:
    fontFamily: Roboto Flex
    fontSize: 32px
    fontWeight: '400'
    lineHeight: 40px
  headline-md:
    fontFamily: Roboto Flex
    fontSize: 28px
    fontWeight: '400'
    lineHeight: 36px
  title-lg:
    fontFamily: Roboto Flex
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 28px
  title-md:
    fontFamily: Roboto Flex
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
    letterSpacing: 0.15px
  body-lg:
    fontFamily: Roboto Flex
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.5px
  body-md:
    fontFamily: Roboto Flex
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.25px
  label-lg:
    fontFamily: Roboto Flex
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.1px
  label-sm:
    fontFamily: Roboto Flex
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
  headline-lg-mobile:
    fontFamily: Roboto Flex
    fontSize: 28px
    fontWeight: '400'
    lineHeight: 34px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  margin-mobile: 16px
  margin-tablet: 24px
  gutter: 16px
  component-padding-x: 16px
  component-padding-y: 12px
  stack-sm: 4px
  stack-md: 12px
  stack-lg: 24px
---

## Brand & Style
The design system for this product is rooted in the Material Design 3 (M3) philosophy, tailored for a high-utility native Android experience. The brand personality is **reliable, efficient, and data-driven**, focusing on providing clear insights into fuel consumption and vehicle expenses.

The visual style is **Corporate Modern**, leveraging the systematic rigor of M3. It prioritizes clarity and functional hierarchy to ensure that users can log data quickly and interpret complex analytics at a glance. The interface utilizes high-quality whitespace and a structured layering system to create a professional, "system-app" feel that inspires trust and precision.

## Colors
The palette is built on a dual-primary strategy to categorize information types: **Green** represents efficiency, fuel levels, and "positive" ecological impact, while **Blue** represents financial data, professional analytics, and maintenance records.

In **Light Mode**, we use a crisp white background with a cool-tinted surface (`#F7F9FC`) to subtly differentiate container areas. In **Dark Mode**, we utilize deep charcoals to reduce glare during night-time refueling. Surfaces in dark mode should employ a slight desaturated gradient (top-to-bottom) to maintain depth without sacrificing readability. Semantic colors (Success/Error) follow standard M3 guidelines but are tuned to match the brand's specific green and blue hues.

## Typography
This design system utilizes **Roboto Flex** for its exceptional versatility in data-heavy environments. The variable axes allow for precise control over readability in dense dashboards. 

- **Display & Headlines:** Used for "at-a-glance" fuel economy figures and primary dashboard headers.
- **Titles:** Reserved for card headers and list section titles.
- **Body:** Standardized for log entries and descriptions.
- **Labels:** Used for navigation items, buttons, and chart axis descriptors.
On mobile devices, use the `headline-lg-mobile` token to ensure titles do not wrap awkwardly in the restricted horizontal space of a smartphone screen.

## Layout & Spacing
The layout follows a **Fluid Grid** model based on an 8dp square grid. For mobile, we utilize a 4-column layout with 16dp margins. For tablets and larger foldables, this scales to an 8 or 12-column grid with 24dp margins.

Spacing is categorized into "Stack" units for vertical rhythm and "In-set" units for component internals. Vertical density is critical for history logs; however, dashboard elements must remain airy to highlight key metrics. Content should reflow from a single column on mobile to a multi-pane layout on tablets (e.g., List on left, Details on right).

## Elevation & Depth
In alignment with Material Design 3, we use **Tonal Layers** rather than heavy drop shadows to communicate depth. Surface containers use color overlays to indicate elevation:
- **Level 0 (Background):** Base color (#FFFFFF or #121212).
- **Level 1 (Cards):** Subtle tonal shift, used for the main dashboard cards.
- **Level 2 (Active elements):** Higher contrast for focused states.

In Dark Mode, elevation is further expressed through "surface tint" overlays of the primary green or blue at very low opacities (1-5%), which helps elements "glow" slightly against the charcoal background without causing visual fatigue.

## Shapes
The shape language is defined by **large, friendly corner radii** that contrast with the technical nature of the data. 

- **Main Cards:** Use `rounded-xl` (24px) to create distinct, contained sections of data.
- **Buttons & Inputs:** Use `rounded-lg` (16px) for a modern, tactile feel.
- **Floating Action Buttons (FAB):** Follow M3 specs for rounded-square shapes (standard) or fully rounded pill-shapes (extended).
- **Chips:** Fully rounded (pill-shaped) for fuel type tags or filter status.

## Components
- **Buttons:** Primary buttons use the brand green with high-contrast text. Use the "Filled" style for logging fuel and "Outlined" for secondary actions like "View Receipt."
- **Floating Action Button (FAB):** A large, green FAB is the primary entry point for "Add Fuel Log." Use the **Speed Dial** pattern to allow quick access to "Add Expense" or "Note."
- **Bottom Navigation:** Uses 4 items with active state indicators (tonal capsules) as per M3.
- **Cards:** Dashboard cards should feature a 24px radius. In Dark Mode, cards utilize a subtle linear gradient from `#2A2A2A` to `#1E1E1E` to enhance the "tactile" feel.
- **Charts:** Line and bar charts should use a stroke width of 3dp. Efficiency lines use Primary Green; expense bars use Primary Blue. Grid lines must be minimal and low-contrast.
- **Input Fields:** Filled text fields with bottom-line indicators, utilizing a 16px top-corner radius to match the overall soft aesthetic.
- **Lists:** Use the standard M3 list item height (72dp for two-line items) with 16dp horizontal padding.