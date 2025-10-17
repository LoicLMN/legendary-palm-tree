import { Chapter } from './chapter';

export interface Book {
  id: string; // a guid
  title: string;
  chapters: Chapter[];
}
