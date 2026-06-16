# StartTech Frontend

This is the React frontend for the StartTech full-stack application. It provides a highly responsive, modern user interface built with Vite, TypeScript, Tailwind CSS, and TanStack Router.

## 🚀 Technologies Used
* **Framework**: React 19 + TypeScript
* **Build Tool**: Vite (for rapid HMR and optimized production builds)
* **Styling**: Tailwind CSS for utility-first responsive design
* **Routing**: TanStack Router (formerly React Location)
* **State Management**: TanStack Query for data fetching and caching
* **Deployment**: AWS S3 Static Website Hosting behind Amazon CloudFront CDN

## 🛠️ Local Development

### Prerequisites
* **Node.js**: Version 22 or higher.

### Getting Started
1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Configure Environment Variables**
   Create a `.env` file based on the provided example and set the backend API URL.
   ```bash
   cp .env.example .env
   # Ensure VITE_API_BASE_URL points to your local Go backend or production ALB
   ```

3. **Start the Development Server**
   ```bash
   npm run dev
   ```
   The application will be available at `http://localhost:5173`.

## 📦 Build & Production

To create a production-optimized build:
```bash
npm run build
```
This generates the static assets inside the `dist/` directory.

### Code Quality
Run ESLint to check for code quality and formatting issues:
```bash
npm run lint
```

## 🔄 CI/CD Deployment

Deployments to production are completely automated via **GitHub Actions**.
When changes are merged into the `master` branch:
1. **Build Job**: The pipeline runs `npm audit`, performs linting, and executes `npm run build`.
2. **Deploy Job**: Using OIDC authentication, the pipeline syncs the `dist/` artifacts directly to the designated **Amazon S3** bucket.
3. **Invalidation**: The pipeline automatically invalidates the **CloudFront** cache to ensure global users receive the latest application version immediately.

See `.github/workflows/frontend-ci-cd.yml` in the root repository for the full pipeline definition.
