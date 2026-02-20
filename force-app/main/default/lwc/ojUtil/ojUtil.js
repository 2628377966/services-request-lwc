import RESOURCES from '@salesforce/resourceUrl/OneJourneyResources';
import { getSteps, getFields, getSignupFields, getSignupSteps } from "./constant";

export function getResourceURLWithBrand(brand, resourceName) {
    return `${RESOURCES}/${brand.replace(/\s/g, '').toLowerCase()}${resourceName}.svg#${resourceName.toLowerCase()}`;
}

export function getResourceURL(resourceName) {
    return `${RESOURCES}/${resourceName}.svg#${resourceName}`;
}

export function getIconURL(resourceName) {
    return `${RESOURCES}/${resourceName}.png`;
}

export function setCSSProperties(componentCSS, cssClass, styleString) {
    const declarations = styleString.split(';').filter(declaration => declaration.trim() !== '');
    declarations.forEach(declaration => {
        const [property, value] = declaration.split(':').map(item => item.trim());
        componentCSS.style.setProperty(`--${cssClass}-${property}`, value);
    });
}

export function setFont(componentCSS, brandFont) {
    componentCSS.style.setProperty('--dxp-s-button-font-family', brandFont);
    componentCSS.style.setProperty('--dxp-g-root-font-family', brandFont);
    componentCSS.style.setProperty('--dxp-s-body-font-family', brandFont);
    componentCSS.style.setProperty('--dxp-s-body-small-font-family', brandFont);
    componentCSS.style.setProperty('--dxp-g-heading-font-family', brandFont);
    componentCSS.style.setProperty('--dxp-s-text-heading-small-font-family', brandFont);
    componentCSS.style.setProperty('--dxp-s-text-heading-medium-font-family', brandFont);
    componentCSS.style.setProperty('--dxp-s-text-heading-large-font-family', brandFont);
    componentCSS.style.setProperty('--dxp-c-monospace-font-family', brandFont);
    componentCSS.style.setProperty('--dxp-s-form-element-label-font-family', brandFont);
};

export function getAllSteps() {
    return getSteps();
};

export function getRequiredFields() {
    return getFields();
};

export function getAllSignupSteps() {
    return getSignupSteps();
};

export function getAllSignupFields() {
    return getSignupFields();
};